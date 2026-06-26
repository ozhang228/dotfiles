import type { ReactNode } from "react";
import type { MDXComponents } from "mdx/types.js";

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
};

type FileMapProps = {
  items: FileMapItem[];
};

export function FileMap({ items }: FileMapProps) {
  return <section className="fileMap">{items.map(renderFileMapItem)}</section>;
}

function renderFileMapItem({ path, action }: FileMapItem) {
  return (
    <div className="fileMapItem" key={path}>
      <code>{path}</code>
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
};
