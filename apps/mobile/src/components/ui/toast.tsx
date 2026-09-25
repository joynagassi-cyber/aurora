/**
 * shadcn/ui Toast (ui-libraries.md S1: "Toast / Notifications — shadcn/ui").
 *
 * Non-blocking feedback, auto-dismiss 3s (5 UX states S6: success = Toast).
 * Headless Radix primitives, skinned with Aurora design tokens (AD-17).
 */
import * as React from 'react';
import * as ToastPrimitives from '@radix-ui/react-toast';
import { cn } from '../../lib/utils';

export interface ToastProps extends React.ComponentPropsWithoutRef<typeof ToastPrimitives.Root> {
  variant?: 'default' | 'destructive';
  /** auto-dismiss delay in ms (default 3000 — 5 UX states S6). */
  duration?: number;
}

export function Toast({ variant = 'default', duration = 3000, className, ...props }: ToastProps) {
  return (
    <ToastPrimitives.Root
      duration={duration}
      className={cn(
        'pointer-events-auto relative flex w-full items-center justify-between gap-3 overflow-hidden rounded-md border p-4 pr-8 shadow-lg transition-all',
        variant === 'destructive' && 'border-red-600 bg-red-600 text-white',
        className,
      )}
      {...props}
    />
  );
}

export function ToastTitle({ className, ...props }: React.ComponentPropsWithoutRef<typeof ToastPrimitives.Title>) {
  return <ToastPrimitives.Title className={cn('text-sm font-semibold', className)} {...props} />;
}

export function ToastDescription({ className, ...props }: React.ComponentPropsWithoutRef<typeof ToastPrimitives.Description>) {
  return <ToastPrimitives.Description className={cn('text-sm opacity-90', className)} {...props} />;
}

export function ToastAction({ className, ...props }: React.ComponentPropsWithoutRef<typeof ToastPrimitives.Action>) {
  return <ToastPrimitives.Action className={cn('inline-flex h-8 flex-1 items-center justify-center rounded-md bg-transparent px-4 text-sm font-medium', className)} {...props} />;
}

export function ToastClose({ className, ...props }: React.ComponentPropsWithoutRef<typeof ToastPrimitives.Close>) {
  return <ToastPrimitives.Close className={cn('absolute right-2 top-2 rounded-md p-1', className)} {...props} />;
}

export const ToastProvider = ToastPrimitives.Provider;
export const ToastViewport = ToastPrimitives.Viewport;
