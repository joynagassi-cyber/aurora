/**
 * @aurora/engineering-adapters — wave 2, VECTOR.
 *
 * AD-1 vendor isolation: SymPy / SciPy / EPANET / SWMM / GDAL /
 * PostGIS live behind ports in the other packages; this package holds
 * the concrete adapters that import the vendor engines.
 *
 * Features:
 *   - sympy: SymPy 2D/3D beam + matrices (SymPy-ready, built-in
 *     numeric fallback when the external-engine bridge is not attached)
 */
export * from './sympy.ts';
