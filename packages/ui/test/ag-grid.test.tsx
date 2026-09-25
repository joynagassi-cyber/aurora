/**
 * AgGridTable — virtualization contract (02 §9.2, docs/ui-libraries.md §5).
 *
 * CI gate: 1000 rows rendered via the AG Grid component. The row model
 * virtualizes (rowBuffer 10 on mobile, 50 desktop — docs §5). What we
 * assert headless:
 *   - the component renders without crashing on 1000 rows;
 *   - the canonical UX states (05 §3.7) are all reachable via
 *     `data-state` on the component root.
 */
import { describe, expect, it } from "vitest";
import * as React from "react";
import {
  AgGridTable,
  type AgGridColumnDef,
} from "src/components/ui/AgGridTable";
import { render } from "./render";

interface Row {
  id: string;
  label: string;
  value: number;
}

const COLS: AgGridColumnDef<Row>[] = [
  { field: "id", headerName: "ID", mono: true },
  { field: "label", headerName: "Libellé" },
  { field: "value", headerName: "Valeur", mono: true },
];

function makeRows(n: number): Row[] {
  return Array.from({ length: n }, (_, i) => ({
    id: `r${i}`,
    label: `Ligne ${i}`,
    value: i,
  }));
}

type GridProps = React.ComponentProps<typeof AgGridTable<Row>>;

describe("AgGridTable virtualization (02 §9.2)", () => {
  it("renders 1000 rows without crashing (row model virtualized by default)", () => {
    const rows = makeRows(1000);
    const { container, unmount } = render(
      <AgGridTable rows={rows} columns={COLS} virtualized />,
    );
    const root = container.querySelector('[data-aurora-component="AgGridTable"]');
    expect(root).toBeTruthy();
    // 1000 rows in data; the grid virtualizes — DOM row count is small
    // (rowBuffer + viewport), NOT 1000.
    const domRows = container.querySelectorAll(".ag-row, [role='row']");
    expect(domRows.length).toBeLessThan(1000);
    expect(domRows.length).toBeGreaterThan(0);
    unmount();
  });

  it("exposes the canonical UX states via data-state (05 §3.7)", () => {
    const cases: Array<{ state: string; props: GridProps }> = [
      {
        state: "idle",
        props: { rows: makeRows(10), columns: COLS },
      },
      {
        state: "loading",
        props: { rows: [], columns: COLS, loading: true },
      },
      {
        state: "error",
        props: {
          rows: makeRows(10),
          columns: COLS,
          errorMessage: "Erreur réseau",
          onRetry: () => undefined,
        },
      },
      {
        state: "empty",
        props: { rows: [], columns: COLS },
      },
    ];
    for (const c of cases) {
      const { container, unmount } = render(<AgGridTable {...c.props} />);
      const root = container.querySelector(
        '[data-aurora-component="AgGridTable"]',
      ) as HTMLElement;
      expect(root.dataset.state, `state ${c.state}`).toBe(c.state);
      unmount();
    }
  });
});
