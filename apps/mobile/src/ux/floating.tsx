/**
 * Floating capture surface (L8 — _floating-surfaces §1 BottomSheet + §6
 * FAB). A FAB + BottomSheet pairing: the FAB opens a capture sheet whose
 * rows route to REAL screens (Inbox capture / new goal / ask the agent) —
 * a pure view, no business logic (feature-registry S4). Stacking per
 * 05 §3.5 (z-sheet 30, above content). focus-trap + 44px + aria.
 *
 * Token-only (no Tailwind): this is the mobile page-layer stand-in for the
 * @aurora/ui shadcn Sheet (which needs the mobile Tailwind build).
 */
import { Plus } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';

export interface CaptureSheetRow {
  key: string;
  label: string;
  to: string;
  icon: 'capture' | 'goal' | 'agent';
}

const ROW_ICONS: Record<CaptureSheetRow['icon'], typeof Plus> = {
  capture: Plus,
  goal: Plus,
  agent: Plus,
};

/** A minimal, token-styled BottomSheet + FAB capture surface. */
export function CaptureFab({
  rows,
  label = 'Nouveau',
}: {
  rows: CaptureSheetRow[];
  label?: string;
}) {
  const [open, setOpen] = useState(false);
  const navigate = useNavigate();
  const scrimRef = useRef<HTMLDivElement>(null);
  const fabRef = useRef<HTMLButtonElement>(null);

  // Basic focus management: trap on open, restore to the FAB on close
  // (05 §3.5 / _floating-surfaces §9 focus-trap).
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        setOpen(false);
        fabRef.current?.focus();
      }
    };
    scrimRef.current?.focus();
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [open]);

  function choose(to: string) {
    setOpen(false);
    fabRef.current?.focus();
    navigate(to);
  }

  return (
    <>
      <button
        ref={fabRef}
        className="aurora-fab aurora-tap"
        aria-label={label}
        aria-expanded={open}
        aria-haspopup="dialog"
        onClick={() => setOpen((o) => !o)}
      >
        <Plus size={24} aria-hidden />
      </button>

      {open && (
        <div
          ref={scrimRef}
          className="aurora-sheet-scrim"
          role="dialog"
          aria-modal="true"
          aria-label={label}
          tabIndex={-1}
          onClick={(e) => {
            if (e.target === e.currentTarget) setOpen(false);
          }}
        >
          <div className="aurora-sheet" role="menu">
            <div className="aurora-sheet-handle" aria-hidden />
            <p className="aurora-sheet-title">{label}</p>
            {rows.map((r) => {
              const Icon = ROW_ICONS[r.icon];
              return (
                <button
                  key={r.key}
                  className="aurora-sheet-item aurora-tap"
                  role="menuitem"
                  onClick={() => choose(r.to)}
                >
                  <Icon size={20} aria-hidden />
                  {r.label}
                </button>
              );
            })}
          </div>
        </div>
      )}
    </>
  );
}
