// The shop page looks up a landmark's reviews by the SAME key the App computes client-side
// (PlaceReviewService.key(name:coordinate:)) — this has to come out byte-identical, or a
// landmark whose rounded coordinate lands on a whole degree would silently never find its
// reviews (Swift's Double always prints a decimal; JS drops it for whole numbers).
import { placeKey, swiftDoubleString } from '../functions/shop/[id].js';

let failed = false;
const check = (label, cond, detail) => { console.log(`${cond ? 'PASS' : 'FAIL'} - ${label}`); if (!cond) { failed = true; if (detail) console.log('   ', detail); } };

check('a whole-number coordinate gets a trailing .0, matching Swift\'s Double.description', swiftDoubleString(121) === '121.0');
check('a fractional coordinate is left as-is', swiftDoubleString(24.83) === '24.83');
check('zero also gets the trailing .0', swiftDoubleString(0) === '0.0');
check('a negative whole number gets it too', swiftDoubleString(-8) === '-8.0');

check('a normal case matches the App\'s "name_lat_lon" shape', placeKey('阿明牛肉麵', 24.83, 121.517) === '阿明牛肉麵_24.83_121.517');
check('a coordinate that rounds to a whole degree still gets the .0 the App would produce', placeKey('阿明牛肉麵', 24.83, 121) === '阿明牛肉麵_24.83_121.0');
check('rounding to 4 decimal places matches the App\'s own (lat*10000).rounded()/10000', placeKey('x', 24.833344, 121.0) === 'x_24.8333_121.0');

process.exit(failed ? 1 : 0);
