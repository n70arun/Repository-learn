import os
import asyncio
from datetime import datetime
from playwright.async_api import async_playwright

class PlaywrightReporter:
    def __init__(self, report_dir="playwright_report", headless=False):
        """
        Initialize the PlaywrightReporter class.

        Args:
            report_dir (str): Directory where reports and screenshots will be saved.
            headless (bool): Whether to run the browser in headless mode.
        """
        self.report_dir = report_dir
        os.makedirs(self.report_dir, exist_ok=True)  # Ensure the report directory exists.
        self.steps = []  # List to store details of each step (description, status, etc.).
        self.page = None  # Placeholder for the browser page instance.
        self.headless = headless  # Whether the browser runs in headless mode.

    async def __aenter__(self):
        """
        Enter the async context manager. Starts the browser.
        """
        await self.start_browser()
        return self

    async def __aexit__(self, exc_type, exc, tb):
        """
        Exit the async context manager. Stops the browser and generates the report.
        """
        await self.stop_browser()

    async def start_browser(self):
        """
        Start the Playwright browser and create a new page for interaction.

        Returns:
            page: The browser page instance.
        """
        self.playwright = await async_playwright().start()  # Start Playwright.
        self.browser = await self.playwright.chromium.launch(headless=self.headless)  # Launch Chromium browser.
        self.page = await self.browser.new_page()  # Create a new page.
        return self.page

    async def stop_browser(self):
        """
        Stop the browser and generate the HTML report.
        """
        await self.browser.close()  # Close the browser.
        await self.playwright.stop()  # Stop Playwright.
        self.generate_report()  # Generate the HTML report.

    async def record_step(self, description, action):
        """
        Record a test step by executing an action, taking a screenshot, and logging the result.

        Args:
            description (str): Description of the test step.
            action (callable): An async function representing the action to perform.

        Raises:
            Exception: Re-raises any exception encountered during the action.
        """
        try:
            # Execute the action provided by the user.
            await action()
            # Save a screenshot for the step.
            screenshot_path = os.path.join(
                self.report_dir, f"{len(self.steps)+1:02d}.png"  # Save screenshot with step number.
            )
            await self.page.screenshot(path=screenshot_path)  # Take a screenshot.
            # Log the step as passed.
            self.steps.append({"desc": description, "status": "Pass", "screenshot": screenshot_path})
        except Exception as e:
            # Log the step as failed and capture the error.
            self.steps.append({"desc": description, "status": "Fail", "error": str(e)})
            raise  # Re-raise the exception for debugging.

    def generate_report(self):
        """
        Generate an HTML report summarizing the test steps, including screenshots and statuses.
        """
        report_path = os.path.join(self.report_dir, "report.html")  # Path for the HTML report.
        total_steps = len(self.steps)  # Total number of steps.
        passed_steps = sum(1 for step in self.steps if step["status"] == "Pass")  # Count passed steps.
        failed_steps = total_steps - passed_steps  # Count failed steps.

        with open(report_path, "w") as f:
            # Write the HTML structure and styles.
            f.write("<html><head><title>Playwright Test Report</title>")
            f.write(
                "<style>body{font-family:sans-serif;} "
                ".step{margin-bottom:20px;} "
                "img{border:1px solid #ccc;max-width:100%;} "
                ".pass{color:green;} .fail{color:red;}</style>"
            )
            f.write("</head><body>")
            # Write the report header with summary.
            f.write(f"<h1>Playwright Test Report</h1>")
            f.write(f"<p>Generated: {datetime.now()}</p>")
            f.write(f"<p>Total Steps: {total_steps}, Passed: <span class='pass'>{passed_steps}</span>, Failed: <span class='fail'>{failed_steps}</span></p>")
            # Write details for each step.
            for i, step in enumerate(self.steps, 1):
                f.write(f"<div class='step'><h2>Step {i}: {step['desc']}</h2>")
                if "screenshot" in step:
                    img_name = os.path.basename(step["screenshot"])  # Get the screenshot file name.
                    f.write(f"<img src='{img_name}' alt='Step {i} screenshot'/>")
                if "status" in step:
                    status_class = "pass" if step["status"] == "Pass" else "fail"  # Determine status class.
                    f.write(f"<p>Status: <span class='{status_class}'>{step['status']}</span></p>")
                if "error" in step:
                    f.write(f"<p style='color:red;'>Error: {step['error']}</p>")  # Display error if present.
                f.write("</div>")
            f.write("</body></html>")

        print(f"✅ Report generated: {report_path}")  # Print confirmation message.

# Example usage of the PlaywrightReporter class.
async def main():
    async with PlaywrightReporter(headless=True) as reporter:
        page = reporter.page
        # Record steps with descriptions and actions.
        await reporter.record_step("Navigate to example.com", lambda: page.goto("https://example.com"))
        await reporter.record_step("Check title", lambda: page.wait_for_selector("h1"))

# Run the main function.
asyncio.run(main())
