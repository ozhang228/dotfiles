import { basename } from "node:path";
import {
  CustomEditor,
  type ExtensionAPI,
  type KeybindingsManager,
} from "@earendil-works/pi-coding-agent";
import {
  matchesKey,
  truncateToWidth,
  visibleWidth,
  type EditorTheme,
  type TUI,
} from "@earendil-works/pi-tui";

const compactTokens = new Intl.NumberFormat("en", {
  notation: "compact",
  maximumFractionDigits: 1,
});

function toolbarLine({ left, right, width }: { left: string; right: string; width: number }) {
  const innerWidth = Math.max(0, width - 4);
  const rightText = truncateToWidth(right, Math.floor(innerWidth * 0.7), "…");
  const leftText = truncateToWidth(
    left,
    Math.max(0, innerWidth - visibleWidth(rightText) - 2),
    "…",
  );
  const gap = " ".repeat(
    Math.max(0, innerWidth - visibleWidth(leftText) - visibleWidth(rightText)),
  );
  return truncateToWidth(`  ${leftText}${gap}${rightText}  `, width);
}

export class CozyEditor extends CustomEditor {
  private bottomBorder = "";

  constructor(tui: TUI, theme: EditorTheme, keybindings: KeybindingsManager) {
    super(tui, theme, keybindings, { paddingX: 3, embedWorkingStatus: true });
  }

  setPaddingX(padding: number) {
    // Pi reapplies its global padding when installing a custom editor. Reserve space for the frame.
    super.setPaddingX(Math.max(3, padding));
  }

  protected renderTopBorder(width: number, hiddenLineCount: number) {
    if (width < 8) return super.renderTopBorder(width, hiddenLineCount);
    return (
      this.borderColor("╭") +
      super.renderTopBorder(width - 2, hiddenLineCount) +
      this.borderColor("╮")
    );
  }

  protected renderBottomBorder(width: number, hiddenLineCount: number) {
    if (width < 8) return super.renderBottomBorder(width, hiddenLineCount);
    this.bottomBorder =
      this.borderColor("╰") +
      super.renderBottomBorder(width - 2, hiddenLineCount) +
      this.borderColor("╯");
    return this.bottomBorder;
  }

  render(width: number) {
    const lines = super.render(width);
    if (width < 8) return lines;
    const bottomIndex = lines.indexOf(this.bottomBorder);
    // Keep native rows and columns so mouse placement, autocomplete and cursor markers stay aligned.
    return lines.map((line, index) =>
      index > 0 && index < bottomIndex
        ? this.borderColor("│") +
          (index === 1 ? this.borderColor("❯") : " ") +
          line.slice(2, -1) +
          this.borderColor("│")
        : line,
    );
  }
}

export default function cozyPrompt(pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    if (!ctx.hasUI) return;

    ctx.ui.setFooter((tui, _theme, footerData) => {
      const unsubscribe = footerData.onBranchChange(() => tui.requestRender());
      const unsubscribeInput = ctx.ui.onTerminalInput((data) => {
        if (matchesKey(data, "ctrl+c") && !ctx.isIdle()) return { data: "\x1b" };
        return undefined;
      });
      ctx.ui.setWidget("cozy-prompt-toolbar", undefined);
      return {
        dispose() {
          unsubscribeInput();
          unsubscribe();
        },
        invalidate() {},
        render(width) {
          const theme = ctx.ui.theme;
          const branch = footerData.getGitBranch();
          const project = basename(ctx.cwd) || ctx.cwd;
          const left =
            theme.fg("mdHeading", project) + (branch ? theme.fg("dim", ` / ${branch}`) : "");
          const usage = ctx.getContextUsage();
          const capacity = usage?.contextWindow ?? ctx.model?.contextWindow;
          const used =
            typeof usage?.tokens === "number"
              ? compactTokens.format(usage.tokens).toLowerCase()
              : "—";
          const total =
            typeof capacity === "number" ? compactTokens.format(capacity).toLowerCase() : "—";
          const percent =
            typeof usage?.percent === "number" ? ` · ${Math.round(usage.percent)}%` : "";
          const context = `${used} / ${total}${percent}`;
          const model = ctx.model?.name || ctx.model?.id || "no model";
          const separator = theme.fg("dim", " · ");
          const right =
            theme.fg("accent", model) +
            separator +
            theme.fg("mdCode", pi.getThinkingLevel()) +
            separator +
            theme.fg("mdQuoteBorder", context);
          const lines = [toolbarLine({ left, right, width })];
          const statuses = [...footerData.getExtensionStatuses().values()].join(" · ");
          if (statuses) lines.push(truncateToWidth(`  ${statuses}`, width));
          return lines;
        },
      };
    });

    ctx.ui.setEditorComponent((tui, theme, keybindings) => new CozyEditor(tui, theme, keybindings));
  });
}
