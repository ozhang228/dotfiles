import Plan from "../.runtime/plan.mdx";
import { planComponents } from "./planComponents";
import "./styles.css";

export function App() {
  return (
    <main className="page">
      <article className="plan">
        <Plan components={planComponents} />
      </article>
    </main>
  );
}
