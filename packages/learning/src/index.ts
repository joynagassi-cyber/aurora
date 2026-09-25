/**
 * @aurora/learning — Learning + Knowledge module (wave 2, SAPPHO).
 *
 * Boundary (AD-1 / AD-2 / AD-7): pure domain services over the AD-15
 * SSoT types (`@aurora/domain`). No vendor SDKs, no DOM. The module
 * writes its own tables only (AD-7); heavy work is persisted in
 * `job_queue` (AD-8); it emits exactly two AD-9 events
 * (`CourseImported`, `FlashcardReviewed`) and observes everything else
 * through the events table / public views.
 */
export * from './course-import';
export * from './fsrs';
export * from './mirror-cognitive';
export * from './qcm';
export * from './retrieval';
export * from './semantic-tree';
export * from './study-sheets';
