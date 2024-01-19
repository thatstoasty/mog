from math import max, min


fn cube(v: Float64) -> Float64:
    return v * v * v


fn sq(v: Float64) -> Float64:
    return v * v


fn clamp01(v: Float64) -> Float64:
    """Clamps from 0 to 1."""
    return max(0.0, min(v, 1.0))


fn pi() -> Float64:
    return 3.141592653589793238462643383279502884197169399375105820974944592307816406286


fn max_float64() -> Float64:
    return 1.797693134862315708145274237317043567981e308
