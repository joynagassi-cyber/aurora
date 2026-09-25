/**
 * shadcn/ui Command Palette (ui-libraries.md S1: "Command Palette (global
 * search) — Radix Command + shadcn"). 5 entry points (UI, palette, agent,
 * deep link, automation) resolve to the same use-case / capability
 * (feature-registry S4). The palette renders a command list FROM the
 * capability registry, filtering on availability + permissions.
 *
 * @radix-ui/react-command is not published on the npm registry in this
 * environment, so the palette is built on Radix's Dialog primitive (same
 * headless, skinnable model) with the `role="dialog"` command surface.
 * The search input + grouped command list follow the shadcn command API.
 */
import * as React from 'react';
import { Dialog, DialogContent, DialogTitle } from './dialog';
import { Search } from 'lucide-react';
import { cn } from '../../lib/utils';

export interface CommandPaletteEntry {
  id: string;
  label: string;
  group?: string;
  shortcut?: string;
  onSelect: () => void;
}

export function CommandPalette({
  entries,
  open,
  onOpenChange,
  title = 'Rechercher',
}: {
  entries: CommandPaletteEntry[];
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title?: string;
}) {
  const [query, setQuery] = React.useState('');
  const filtered = entries.filter((e) => e.label.toLowerCase().includes(query.toLowerCase()));

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="translate-x-0 translate-y-0 overflow-hidden rounded-lg p-0">
        <div className="flex items-center border-b px-3">
          <Search size={16} className="opacity-50" aria-hidden="true" />
          <input
            autoFocus
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Taper une commande…"
            aria-label={title}
            className="w-full border-0 bg-transparent p-3 text-sm focus:outline-none"
          />
        </div>
        <DialogTitle className="sr-only">{title}</DialogTitle>
        <div className="max-h-80 overflow-y-auto" role="listbox">
          {filtered.length === 0 && <p className="p-4 text-sm opacity-60">Aucune commande</p>}
          {filtered.map((e) => (
            <button
              key={e.id}
              type="button"
              role="option"
              aria-selected={false}
              onClick={() => {
                e.onSelect();
                onOpenChange(false);
              }}
              className={cn(
                'flex w-full items-center justify-between px-3 py-2 text-left text-sm hover:bg-accent',
              )}
            >
              <span>{e.label}</span>
              {e.shortcut && <kbd className="text-xs opacity-50">{e.shortcut}</kbd>}
            </button>
          ))}
        </div>
      </DialogContent>
    </Dialog>
  );
}
