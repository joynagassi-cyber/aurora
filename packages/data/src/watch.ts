/**
 * @aurora/data — watch contract (03 S3.2, AD-7).
 *
 * `Unsubscribe` is the standard inverse of a `watch()` subscription: call it
 * to stop receiving local-store change events. Kept minimal so the data
 * package stays hexagonal (no vendor dependency, AD-1).
 */
export type Unsubscribe = () => void;
