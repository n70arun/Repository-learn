import asyncio
from Playwright_wrapper import PlaywrightReporter  # Import the reusable wrapper.

async def my_test():
    """
    Example test script using the PlaywrightReporter wrapper.
    """
    # Initialize the PlaywrightReporter instance.
    reporter = PlaywrightReporter(headless=True)  # Set headless mode to True.
    page = await reporter.start_browser()  # Start the browser and get the page instance.

    # Record test steps with descriptions and actions.
    await reporter.record_step("Go to Playwright site", lambda: page.goto("https://playwright.dev"))
    await reporter.record_step("Click Docs", lambda: page.get_by_role("link", name="Docs").click())
    await reporter.record_step("Click Python", lambda: page.get_by_role("link", name="Python").click())

    # Stop the browser and generate the report.
    await reporter.stop_browser()

# Run the test script.
if __name__ == "__main__":
    asyncio.run(my_test())
