from .helpers import cube, clamp01, sq, pi, max_float64


fn clamped(rgb: RGB) -> RGB:
    return RGB(clamp01(rgb.R), clamp01(rgb.G), clamp01(rgb.B))


fn linearize(v: Float64) -> Float64:
    if v <= 0.04045:
        return v / 12.92

    var lhs: Float64 = (v + 0.055) / 1.055
    var rhs: Float64 = 2.4
    return lhs**rhs


fn linear_rgb_to_xyz(r: Float64, g: Float64, b: Float64) -> (Float64, Float64, Float64):
    var x: Float64 = 0.41239079926595948 * r + 0.35758433938387796 * g + 0.18048078840183429 * b
    var y: Float64 = 0.21263900587151036 * r + 0.71516867876775593 * g + 0.072192315360733715 * b
    var z: Float64 = 0.019330818715591851 * r + 0.11919477979462599 * g + 0.95053215224966058 * b

    return x, y, z


fn luv_to_xyz_white_ref(
    l: Float64, u: Float64, v: Float64, wref: DynamicVector[Float64]
) -> (Float64, Float64, Float64):
    var y: Float64
    if l <= 0.08:
        y = wref[1] * l * 100.0 * 3.0 / 29.0 * 3.0 / 29.0 * 3.0 / 29.0
    else:
        y = wref[1] * cube((l + 0.16) / 1.16)

    var un: Float64 = 0
    var vn: Float64 = 0
    un, vn = xyz_to_uv(wref[0], wref[1], wref[2])

    var x: Float64 = 0
    var z: Float64 = 0
    if l != 0.0:
        var ubis = (u / (13.0 * l)) + un
        var vbis = (v / (13.0 * l)) + vn
        x = y * 9.0 * ubis / (4.0 * vbis)
        z = y * (12.0 - (3.0 * ubis) - (20.0 * vbis)) / (4.0 * vbis)
    else:
        x = 0.0
        y = 0.0

    return x, y, z


# For this part, we do as R's graphics.hcl does, not as wikipedia does.
# Or is it the same?
fn xyz_to_uv(x: Float64, y: Float64, z: Float64) -> (Float64, Float64):
    var denom = x + (15.0 * y) + (3.0 * z)
    var u: Float64
    var v: Float64

    if denom == 0.0:
        u = 0.0
        v = 0.0

        return u, v

    u = 4.0 * x / denom
    v = 9.0 * y / denom

    return u, v


fn xyz_to_Luv_white_ref(
    x: Float64, y: Float64, z: Float64, wref: DynamicVector[Float64]
) -> (Float64, Float64, Float64):
    var l: Float64
    if y / wref[1] <= 6.0 / 29.0 * 6.0 / 29.0 * 6.0 / 29.0:
        l = y / wref[1] * (29.0 / 3.0 * 29.0 / 3.0 * 29.0 / 3.0) / 100.0
    else:
        l = 1.16 * math.cbrt(y / wref[1]) - 0.16

    var ubis: Float64
    var vbis: Float64
    ubis, vbis = xyz_to_uv(x, y, z)

    var un: Float64
    var vn: Float64
    un, vn = xyz_to_uv(wref[0], wref[1], wref[2])

    var u: Float64
    var v: Float64
    u = 13.0 * l * (ubis - un)
    v = 13.0 * l * (vbis - vn)

    return l, u, v


fn LuvToLuvLCh(L: Float64, u: Float64, v: Float64) -> (Float64, Float64, Float64):
    # Oops, floating point workaround necessary if u ~= v and both are very small (i.e. almost zero).
    var h: Float64
    if math.abs(v - u) > 1e-4 and math.abs(u) > 1e-4:
        h = math.mod(
            57.29577951308232087721 * math.atan2(v, u) + 360.0, 360.0
        )  # Rad2Deg
    else:
        h = 0.0

    var l = L
    var c = math.sqrt(sq(u) + sq(v))

    return l, c, h


fn hSLuvD65() -> DynamicVector[Float64]:
    var vector: DynamicVector[Float64] = DynamicVector[Float64]()
    vector.append(0.95045592705167)
    vector.append(1.0)
    vector.append(1.089057750759878)

    return vector


fn get_bounds_matrix() -> DynamicVector[DynamicVector[Float64]]:
    var m = DynamicVector[DynamicVector[Float64]]()
    var m1 = DynamicVector[Float64]()
    m1.append(3.2409699419045214)
    m1.append(-1.5373831775700935)
    m1.append(-0.49861076029300328)
    m.append(m1)

    var m2 = DynamicVector[Float64]()
    m2.append(-0.96924363628087983)
    m2.append(-0.96924363628087983)
    m2.append(0.041555057407175613)
    m.append(m2)

    var m3 = DynamicVector[Float64]()
    m3.append(0.055630079696993609)
    m3.append(-0.20397695888897657)
    m3.append(1.0569715142428786)
    m.append(m3)

    return m


alias bounds_matrix = get_bounds_matrix()


fn get_bounds(l: Float64) -> DynamicVector[DynamicVector[Float64]]:
    var sub2: Float64
    var sub1 = (l + 16.0**3.0) / 1560896.0
    var epsilon = 0.0088564516790356308
    var kappa = 903.2962962962963

    var ret: DynamicVector[DynamicVector[Float64]] = DynamicVector[
        DynamicVector[Float64]
    ]()
    var ret1 = DynamicVector[Float64]()
    ret1.append(0)
    ret1.append(0)

    var ret2 = DynamicVector[Float64]()
    ret2.append(0)
    ret2.append(0)

    var ret3 = DynamicVector[Float64]()
    ret3.append(0)
    ret3.append(0)

    var ret4 = DynamicVector[Float64]()
    ret4.append(0)
    ret4.append(0)

    var ret5 = DynamicVector[Float64]()
    ret5.append(0)
    ret5.append(0)

    var ret6 = DynamicVector[Float64]()
    ret6.append(0)
    ret6.append(0)

    ret.append(ret1)
    ret.append(ret2)
    ret.append(ret3)
    ret.append(ret4)
    ret.append(ret5)
    ret.append(ret6)

    var m = bounds_matrix

    if sub1 > epsilon:
        sub2 = sub1
    else:
        sub2 = l / kappa

    for i in range(len(m)):
        var k = 0
        while k < 2:
            var top1 = (284517.0 * m[i][0] - 94839.0 * m[i][2]) * sub2
            var top2 = (
                838422.0 * m[i][2] + 769860.0 * m[i][1] + 731718.0 * m[i][0]
            ) * l * sub2 - 769860.0 * Float64(k) * l
            var bottom = (
                632260.0 * m[i][2] - 126452.0 * m[i][1]
            ) * sub2 + 126452.0 * Float64(k)
            ret[i * 2 + k][0] = top1 / bottom
            ret[i * 2 + k][1] = top2 / bottom
            k += 1

    return ret


fn length_of_ray_until_intersect(theta: Float64, x: Float64, y: Float64) -> Float64:
    return y / (math.sin(theta) - x * math.cos(theta))


fn max_chroma_for_lh(l: Float64, h: Float64) -> Float64:
    var hRad = h / 360.0 * pi * 2.0
    var minLength = max_float64
    var bounds = get_bounds(l)

    for i in range(len(bounds)):
        var line = bounds[i]
        var length = length_of_ray_until_intersect(hRad, line[0], line[1])
        if length > 0.0 and length < minLength:
            minLength = length

    return minLength


fn LuvLch_to_HSLuv(l: Float64, c: Float64, h: Float64) -> (Float64, Float64, Float64):
    # [-1..1] but the code expects it to be [-100..100]
    var tmp_l: Float64 = l * 100.0
    var tmp_c: Float64 = c * 100.0

    var s: Float64
    var max: Float64
    if l > 99.9999999 or l < 0.00000001:
        s = 0.0
    else:
        max = max_chroma_for_lh(l, h)
        s = c / max * 100.0

    return h, clamp01(s / 100.0), clamp01(l / 100.0)


fn xyz_to_linear_rgb(x: Float64, y: Float64, z: Float64) -> (Float64, Float64, Float64):
    """Converts from CIE XYZ-space to Linear RGB space."""
    var r = (3.2409699419045214 * x) - (1.5373831775700935 * y) - (
        0.49861076029300328 * z
    )
    var g = (-0.96924363628087983 * x) + (1.8759675015077207 * y) + (
        0.041555057407175613 * z
    )
    var b = (0.055630079696993609 * x) - (0.20397695888897657 * y) + (
        1.0569715142428786 * z
    )

    return r, g, b


fn delinearize(v: Float64) -> Float64:
    if v <= 0.0031308:
        return 12.92 * v

    return 1.055 * (v ** (1.0 / 2.4)) - 0.055


fn LinearRgb(r: Float64, g: Float64, b: Float64) -> RGB:
    return RGB(delinearize(r), delinearize(g), delinearize(b))


fn xyz(x: Float64, y: Float64, z: Float64) -> RGB:
    var r: Float64
    var g: Float64
    var b: Float64

    r, g, b = xyz_to_linear_rgb(x, y, z)
    return LinearRgb(r, g, b)


# Generates a color by using data given in CIE L*u*v* space, taking
# into account a given reference white. (i.e. the monitor's white)
# L* is in [0..1] and both u* and v* are in about [-1..1]
fn LuvWhiteRef(l: Float64, u: Float64, v: Float64, wref: DynamicVector[Float64]) -> RGB:
    var x: Float64
    var y: Float64
    var z: Float64
    x, y, z = luv_to_xyz_white_ref(l, u, v, wref)

    return xyz(x, y, z)


@value
struct RGB:
    var R: Float64
    var G: Float64
    var B: Float64

    fn __str__(self) -> String:
        return (
            "RGB("
            + String(self.R)
            + ", "
            + String(self.G)
            + ", "
            + String(self.B)
            + ")"
        )

    fn LinearRgb(self) -> (Float64, Float64, Float64):
        """LinearRgb converts the color into the linear RGB space (see http://www.sjbrown.co.uk/2004/05/14/gamma-correct-rendering/).
        """
        var r: Float64
        var g: Float64
        var b: Float64

        r = linearize(self.R)
        g = linearize(self.G)
        b = linearize(self.B)
        return r, g, b

    fn xyz(self) -> (Float64, Float64, Float64):
        var r: Float64
        var g: Float64
        var b: Float64
        r, g, b = self.LinearRgb()

        var x: Float64
        var y: Float64
        var z: Float64
        x, y, z = linear_rgb_to_xyz(r, g, b)
        return x, y, z

    fn Luv_white_ref(self, wref: DynamicVector[Float64]) -> (Float64, Float64, Float64):
        """Converts the given color to CIE L*u*v* space, taking into account a given reference white. (i.e. the monitor's white)
        L* is in [0..1] and both u* and v* are in about [-1..1]."""
        var x: Float64
        var y: Float64
        var z: Float64
        x, y, z = self.xyz()

        var l: Float64
        var u: Float64
        var v: Float64
        l, u, v = xyz_to_Luv_white_ref(x, y, z, wref)
        return l, u, v

    fn LuvLCh_white_ref(
        self, wref: DynamicVector[Float64]
    ) -> (Float64, Float64, Float64):
        var l: Float64
        var u: Float64
        var v: Float64
        l, u, v = self.Luv_white_ref(wref)

        return LuvToLuvLCh(l, u, v)

    fn HSLuv(self) -> (Float64, Float64, Float64):
        """Order: sRGB -> Linear RGB -> CIEXYZ -> CIELUV -> LuvLCh -> HSLuv.
        HSLuv returns the Hue, Saturation and Luminance of the color in the HSLuv
        color space. Hue in [0..360], a Saturation [0..1], and a Luminance
        (lightness) in [0..1].
        """
        var wref: DynamicVector[Float64] = hSLuvD65()
        var l: Float64
        var c: Float64
        var h: Float64
        l, c, h = self.LuvLCh_white_ref(wref)

        return LuvLch_to_HSLuv(l, c, h)

    fn distance_HSLuv(self, c2: RGB) -> Float64:
        var h1: Float64
        var s1: Float64
        var l1: Float64
        var h2: Float64
        var s2: Float64
        var l2: Float64

        h1, s1, l1 = self.HSLuv()
        h2, s2, l2 = c2.HSLuv()

        return math.sqrt(sq((h1 - h2) / 100.0) + sq(s1 - s2) + sq(l1 - l2))
