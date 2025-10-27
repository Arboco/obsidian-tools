
const puppeteer = require('puppeteer');

(async () => {
    const url = process.argv[2];

    if (!url) {
        console.error("❌ Please provide a URL as an argument.");
        console.log("Usage: node script.js <URL>");
        process.exit(1);
    }

    const browser = await puppeteer.launch({ headless: false });
    const page = await browser.newPage();

    console.log(`🌍 Navigating to: ${url}`);
    await page.goto(url, { waitUntil: 'networkidle2' });

    async function clickShowAll() {
        const elements = await page.$$('a.a-link-normal');

        for (let element of elements) {
            const textHandle = await element.getProperty('innerText');
            const text = await textHandle.jsonValue();
            
            if (text.trim() === '...more') {
                console.log('🔘 Clicking "Show All" button...');
                await element.click();
                await new Promise(r => setTimeout(r, 2000)); // Wait for content to expand
                return true;
            }
        }
        return false;
    }

    let clicked = await clickShowAll();

    if (clicked) {
        console.log("✅ 'Show All' clicked successfully.");
    } else {
        console.log("⚠️ 'Show All' button not found.");
    }

    const html = await page.content();
    console.log(html);

    await browser.close();
})();
