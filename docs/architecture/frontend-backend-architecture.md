# Frontend / Backend Architecture (pointer)

This document is consolidated into:
- [00-overview.md](./00-overview.md) S3 (system interaction map: User -> Frontend -> Application -> Agent/Feature -> Domain -> Ports -> Adapters -> Data/Jobs/Events/Providers)
- [cross-feature-interactions.md](./cross-feature-interactions.md) (all module-to-module data flows)
- [contract-catalog.md](./contract-catalog.md) S4 (local data contracts: LocalQueryRepository, LocalCommandRepository, SyncStatus)
- [frontend-backend-architecture.md](../../frontend/page-contracts.md) (UI -> Application command -> Contract -> Backend service -> Domain -> Persistence; optimistic update, offline, retry, stale data, errors, conflict, sync)
- [data-ownership-matrix.md](./data-ownership-matrix.md) (module -> own tables / read external / write external / allowed contract)
