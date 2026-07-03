import { Children, isValidElement, useState } from "react";
import type { ReactElement, ReactNode } from "react";
import type { MDXComponents } from "mdx/types.js";

type Change = "added" | "modified" | "removed" | "renamed";

type Badge = string;

type PlanHeaderProps = {
  title: string;
  subtitle?: string;
  badges?: Badge[];
};

export function PlanHeader({ title, subtitle, badges = [] }: PlanHeaderProps) {
  return (
    <header className="planHeader">
      <div>
        <h1>{title}</h1>
        {subtitle === undefined ? undefined : <p className="lead">{subtitle}</p>}
      </div>
      {badges.length === 0 ? undefined : (
        <div className="badgeRow">
          {badges.map(renderBadge)}
        </div>
      )}
    </header>
  );
}

function renderBadge(badge: Badge) {
  return (
    <span className="badge" key={badge}>
      {badge}
    </span>
  );
}

type SummaryGridProps = {
  children: ReactNode;
};

export function SummaryGrid({ children }: SummaryGridProps) {
  return <section className="summaryGrid">{children}</section>;
}

type SummaryCardProps = {
  title: string;
  tone?: "default" | "good" | "warn" | "bad";
  children: ReactNode;
};

export function SummaryCard({ title, tone = "default", children }: SummaryCardProps) {
  return (
    <section className={`summaryCard ${tone}`}>
      <h3>{title}</h3>
      <div>{children}</div>
    </section>
  );
}

type CalloutProps = {
  title: string;
  tone?: "info" | "good" | "warn" | "bad";
  children: ReactNode;
};

export function Callout({ title, tone = "info", children }: CalloutProps) {
  return (
    <aside className={`callout ${tone}`}>
      <strong>{title}</strong>
      <div>{children}</div>
    </aside>
  );
}

type SplitProps = {
  children: ReactNode;
};

export function Split({ children }: SplitProps) {
  return <section className="split">{children}</section>;
}

type PanelProps = {
  title: string;
  children: ReactNode;
};

export function Panel({ title, children }: PanelProps) {
  return (
    <section className="panel">
      <h3>{title}</h3>
      <div>{children}</div>
    </section>
  );
}

type Step = {
  label: string;
  title: string;
  detail: string;
};

type FlowProps = {
  steps: Step[];
};

export function Flow({ steps }: FlowProps) {
  return <section className="flow">{steps.map(renderFlowStep)}</section>;
}

function renderFlowStep({ label, title, detail }: Step) {
  return (
    <section className="flowStep" key={label}>
      <span>{label}</span>
      <h3>{title}</h3>
      <p>{detail}</p>
    </section>
  );
}

type FileMapItem = {
  path: string;
  action: string;
  change?: Change;
};

type FileMapProps = {
  items: FileMapItem[];
};

export function FileMap({ items }: FileMapProps) {
  return <section className="fileMap">{items.map(renderFileMapItem)}</section>;
}

function renderFileMapItem({ path, action, change }: FileMapItem) {
  return (
    <div className="fileMapItem" key={path}>
      <div className="fileMapPath">
        {change === undefined ? undefined : <span className={`badge ${change}`}>{change}</span>}
        <code>{path}</code>
      </div>
      <p>{action}</p>
    </div>
  );
}

type TestItem = {
  name: string;
  why: string;
};

type TestMatrixProps = {
  tests: TestItem[];
};

export function TestMatrix({ tests }: TestMatrixProps) {
  return <section className="testMatrix">{tests.map(renderTestItem)}</section>;
}

function renderTestItem({ name, why }: TestItem) {
  return (
    <section className="testItem" key={name}>
      <code>{name}</code>
      <p>{why}</p>
    </section>
  );
}

type ChecklistProps = {
  items: string[];
};

export function Checklist({ items }: ChecklistProps) {
  return <ul className="checklist">{items.map(renderChecklistItem)}</ul>;
}

function renderChecklistItem(item: string) {
  return <li key={item}>{item}</li>;
}

type MetricGridProps = {
  children: ReactNode;
};

export function MetricGrid({ children }: MetricGridProps) {
  return <section className="metricGrid">{children}</section>;
}

type MetricProps = {
  label: string;
  value: string;
  children?: ReactNode;
};

export function Metric({ label, value, children }: MetricProps) {
  return (
    <section className="metric">
      <span>{label}</span>
      <strong>{value}</strong>
      {children === undefined ? undefined : <p>{children}</p>}
    </section>
  );
}

type DiffLineType = "ctx" | "add" | "del" | "blank";

type DiffLine = {
  ln?: number;
  type: DiffLineType;
  code: string;
  note?: number;
};

type DiffNote = {
  n: number;
  text: string;
};

type DiffProps = {
  filename: string;
  summary?: string;
  before: DiffLine[];
  after: DiffLine[];
  notes?: DiffNote[];
};

export function Diff({ filename, summary, before, after, notes = [] }: DiffProps) {
  return (
    <section className="diff">
      <DiffHead filename={filename} summary={summary} />
      <div className="diffSplit">
        <div className="diffPane">{before.map(renderDiffLine)}</div>
        <div className="diffPane">{after.map(renderDiffLine)}</div>
      </div>
      {notes.length === 0 ? undefined : <DiffNotes notes={notes} />}
    </section>
  );
}

type AnnotatedCodeProps = {
  filename: string;
  summary?: string;
  lines: DiffLine[];
  notes?: DiffNote[];
};

export function AnnotatedCode({ filename, summary, lines, notes = [] }: AnnotatedCodeProps) {
  return (
    <section className="diff annoCode">
      <DiffHead filename={filename} summary={summary} />
      <div>{lines.map(renderDiffLine)}</div>
      {notes.length === 0 ? undefined : <DiffNotes notes={notes} />}
    </section>
  );
}

function DiffHead({ filename, summary }: { filename: string; summary?: string }) {
  return (
    <div className="diffHead">
      <span className="diffPath">{filename}</span>
      {summary === undefined ? undefined : <span className="diffSummary">{summary}</span>}
    </div>
  );
}

function renderDiffLine({ ln, type, code, note }: DiffLine, key: number) {
  return (
    <div className={`diffRow ${type}`} key={key}>
      <span className="ln">{ln ?? ""}</span>
      <span className="code">
        {code}
        {note === undefined ? undefined : <span className="noteMarker">{note}</span>}
      </span>
    </div>
  );
}

function DiffNotes({ notes }: { notes: DiffNote[] }) {
  return (
    <div className="diffNotes">
      {notes.map(({ n, text }) => (
        <div className="note" key={n}>
          <span className="n">{n}</span>
          <p>{text}</p>
        </div>
      ))}
    </div>
  );
}

type ModelField = {
  name: string;
  type: string;
  change?: Change;
  was?: string;
};

type DataModelProps = {
  entity: string;
  fields: ModelField[];
};

export function DataModel({ entity, fields }: DataModelProps) {
  return (
    <section className="dataModel">
      <p className="entityName">{entity}</p>
      <table className="fieldTable">
        <thead>
          <tr>
            <th>field</th>
            <th>type</th>
            <th>change</th>
          </tr>
        </thead>
        <tbody>{fields.map(renderModelField)}</tbody>
      </table>
    </section>
  );
}

function renderModelField({ name, type, change, was }: ModelField) {
  return (
    <tr key={name}>
      <td className="fname">{name}</td>
      <td className="ftype">{type}</td>
      <td>{renderChangeCell(change, was)}</td>
    </tr>
  );
}

function renderChangeCell(change: Change | undefined, was: string | undefined) {
  return (
    <>
      {change === undefined ? undefined : <span className={`badge ${change}`}>{change}</span>}
      {was === undefined ? undefined : (
        <>
          {" "}
          <span className="was">{was}</span>
          <span className="arrow">→</span>
        </>
      )}
    </>
  );
}

type EndpointParam = {
  name: string;
  type: string;
  in?: "path" | "query" | "body";
  change?: Change;
  was?: string;
};

type EndpointExample = {
  label: string;
  json: unknown;
};

type EndpointProps = {
  method: string;
  path: string;
  change?: Change;
  description?: string;
  params?: EndpointParam[];
  examples?: EndpointExample[];
};

export function Endpoint({
  method,
  path,
  change,
  description,
  params = [],
  examples = [],
}: EndpointProps) {
  return (
    <section className="endpoint">
      <div className="endpointHead">
        <span className="methodPill">{method}</span>
        <span className="endpointPath">{path}</span>
        {change === undefined ? undefined : <span className={`badge ${change}`}>{change}</span>}
      </div>
      {description === undefined ? undefined : <p className="endpointDesc">{description}</p>}
      {params.length === 0 ? undefined : (
        <>
          <h4>Params</h4>
          <table className="fieldTable">
            <thead>
              <tr>
                <th>name</th>
                <th>type</th>
                <th>in</th>
                <th>change</th>
              </tr>
            </thead>
            <tbody>{params.map(renderParam)}</tbody>
          </table>
        </>
      )}
      {examples.map(renderExample)}
    </section>
  );
}

function renderParam({ name, type, in: paramIn, change, was }: EndpointParam) {
  return (
    <tr key={name}>
      <td className="fname">{name}</td>
      <td className="ftype">{type}</td>
      <td className="ftype">{paramIn ?? ""}</td>
      <td>{renderChangeCell(change, was)}</td>
    </tr>
  );
}

function renderExample({ label, json }: EndpointExample) {
  return (
    <details className="jsonExplorer" open key={label}>
      <summary>{label}</summary>
      <pre>{JSON.stringify(json, null, 2)}</pre>
    </details>
  );
}

type TabPanelProps = {
  label: string;
  children: ReactNode;
};

export function TabPanel({ children }: TabPanelProps) {
  return <>{children}</>;
}

type TabsProps = {
  children: ReactNode;
};

export function Tabs({ children }: TabsProps) {
  const panels = Children.toArray(children).filter(isValidElement) as ReactElement<TabPanelProps>[];
  const [active, setActive] = useState(0);
  return (
    <section className="tabs">
      <div className="tabBar">
        {panels.map((panel, i) => (
          <button
            key={panel.props.label}
            type="button"
            className={`tabBtn${i === active ? " active" : ""}`}
            onClick={() => setActive(i)}
          >
            {panel.props.label}
          </button>
        ))}
      </div>
      <div className="tabPanel">{panels[active]}</div>
    </section>
  );
}

type DiagramNodeProps = {
  hot?: boolean;
  children: ReactNode;
};

export function DiagramNode({ hot = false, children }: DiagramNodeProps) {
  return <div className={`diagramNode${hot ? " hot" : ""}`}>{children}</div>;
}

export function DiagramConnector({ children = "→" }: { children?: ReactNode }) {
  return <div className="diagramConnector">{children}</div>;
}

export const planComponents: MDXComponents = {
  PlanHeader,
  SummaryGrid,
  SummaryCard,
  Callout,
  Split,
  Panel,
  Flow,
  FileMap,
  TestMatrix,
  Checklist,
  MetricGrid,
  Metric,
  Diff,
  AnnotatedCode,
  DataModel,
  Endpoint,
  Tabs,
  TabPanel,
  DiagramNode,
  DiagramConnector,
};
