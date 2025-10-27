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

    async function clickShowAllButtons() {
        let buttonsClicked = 0;
        const elements = await page.$$('a.a-link-normal');

        for (let element of elements) {
            const textHandle = await element.getProperty('innerText');
            const text = await textHandle.jsonValue();
            
            if (text.trim().toLowerCase() === 'show all') {
                console.log('🔘 Clicking "Show All" button...');
                await element.click();
                buttonsClicked++;
                await new Promise(r => setTimeout(r, 1000)); // Wait for content to expand
            }
        }
        return buttonsClicked;
    }

    async function autoScroll() {
        let lastHeight = await page.evaluate(() => document.body.scrollHeight);
        
        while (true) {
            // Scroll 25% beyond the current height
            const scrollHeight = lastHeight * 0.75;
            
            console.log(`📜 Scrolling to ${scrollHeight}...`);
            await page.evaluate(scrollTo => window.scrollTo(0, scrollTo), scrollHeight);
            await new Promise(r => setTimeout(r, 1500)); // Wait for new content to load

            let newHeight = await page.evaluate(() => document.body.scrollHeight);
            if (newHeight === lastHeight) {
                console.log("✅ No more new content loaded.");
                break;
            }
            lastHeight = newHeight;
        }
    }

    async function expandPage() {
        let changesMade = true;

        while (changesMade) {
            let buttonsClicked = await clickShowAllButtons();
            await autoScroll();
            
            if (buttonsClicked === 0) {
                console.log("🎉 All content is fully expanded!");
                changesMade = false;
            } else {
                console.log(`🔄 Found ${buttonsClicked} more "Show All" buttons. Clicking again...`);
            }
        }
    }

    await expandPage();
    // Save the page HTML
    const html = await page.content();
    console.log(html);

    await browser.close();
})();
