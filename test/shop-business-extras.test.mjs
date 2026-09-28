// The shop page's rendering of the newest Google-Maps-style extras: categorized photos
// (with backward-compat for the plain-string shape), external links, and price range.
import { photoUrl, photoCategory, galleryHtml, linksHtml } from '../functions/shop/[id].js';

let failed = false;
const check = (label, cond, detail) => { console.log(`${cond ? 'PASS' : 'FAIL'} - ${label}`); if (!cond) { failed = true; if (detail) console.log('   ', detail); } };

// ---- photoUrl / photoCategory ----
check('photoUrl reads the url out of an {url, category} object', photoUrl({ url: 'https://x/a.jpg', category: 'food' }) === 'https://x/a.jpg');
check('photoUrl also accepts a bare legacy string', photoUrl('https://x/a.jpg') === 'https://x/a.jpg');
check('photoCategory reads the category out of an object', photoCategory({ url: 'https://x/a.jpg', category: 'menu' }) === 'menu');
check('photoCategory is null for a bare legacy string (no category to read)', photoCategory('https://x/a.jpg') === null);

// ---- galleryHtml ----
check('no photos renders nothing', galleryHtml([]) === '');
{
  const html = galleryHtml([{ url: 'https://x/food.jpg', category: 'food' }]);
  check('a categorized photo gets an <img> for its url', html.includes('src="https://x/food.jpg"'));
  check('...and a visible category badge', html.includes('餐點'));
}
{
  const html = galleryHtml([{ url: 'https://x/o.jpg', category: 'other' }]);
  check('category "other" gets no badge (nothing useful to say)', !html.includes('photo-cat'));
}
{
  const html = galleryHtml(['https://x/legacy.jpg']);
  check('a bare legacy string still renders the image', html.includes('src="https://x/legacy.jpg"'));
  check('...with no category badge at all', !html.includes('photo-cat'));
}
{
  const html = galleryHtml([{ url: 'https://x/a"><script>alert(1)</script>.jpg', category: 'food' }]);
  check('a photo url is HTML-escaped, not injected raw', !html.includes('<script>'));
}

// ---- linksHtml ----
check('no links at all renders nothing', linksHtml(null) === '' && linksHtml(undefined) === '' && linksHtml({}) === '');
{
  const html = linksHtml({ menu: 'https://x/menu', website: 'https://x' });
  check('only the links that are actually set render', html.includes('https://x/menu') && html.includes('https://x') && html.includes('菜單') && html.includes('官網'));
  check('a link kind not set (order/delivery) does not render', !html.includes('線上點餐') && !html.includes('外送'));
}
{
  const html = linksHtml({ menu: 'https://x/"><script>alert(1)</script>' });
  check('a link url is HTML-escaped, not injected raw', !html.includes('<script>'));
}

process.exit(failed ? 1 : 0);
