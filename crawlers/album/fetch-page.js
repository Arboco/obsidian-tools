
const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');

puppeteer.use(StealthPlugin());  // Enable stealth mode

(async () => {
    const browser = await puppeteer.launch({
        headless: false,  // Run in visible mode (change to true if needed)
        args: [
            '--no-sandbox',
            '--disable-blink-features=AutomationControlled',
            '--disable-infobars',
            '--window-size=1280,800'
        ]
    });

    const page = await browser.newPage();

    // Set a real User-Agent to mimic Chrome
    await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36');

    // Mimic real browser properties
    await page.evaluateOnNewDocument(() => {
        Object.defineProperty(navigator, 'webdriver', { get: () => undefined });  // Hide Puppeteer
        Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en'] });
        Object.defineProperty(navigator, 'platform', { get: () => 'Win32' });
    });

    // Set viewport size
    await page.setViewport({ width: 1280, height: 800 });

    // Get URL from command line argument
    const url = process.argv[2] || "https://example.com";
    console.log(`Navigating to: ${url}`);
    
    await page.goto(url, { waitUntil: 'networkidle2' });

    // Simulate user behavior (mouse movement, scrolling)
    await page.mouse.move(200, 200);
    await new Promise(resolve => setTimeout(resolve, 1000));  // ✅ Works in all versions
    await page.mouse.move(400, 400);
    await page.evaluate(() => window.scrollBy(0, 300));  // Scroll down

    // Save the page HTML
    const html = await page.content();
    console.log(html);

    await browser.close();
})();
