// app/javascript/controllers/chart_controller.js
import { Controller } from "@hotwired/stimulus";
import Chart from "chart.js/auto"; // Use "/auto" to register all controllers, scales, etc.

export default class extends Controller {
  // Define a target for the canvas element where the chart will be drawn
  static targets = ["canvas"];

  // Define values to receive data, type, and options from the HTML
  // Stimulus automatically parses JSON strings passed to -value attributes
  static values = {
    type: String, // e.g., 'line', 'bar', 'pie'
    data: Object, // The data structure for Chart.js { labels: [], datasets: [] }
    options: { type: Object, default: {} }, // Optional Chart.js options
  };

  // Property to hold the Chart.js instance
  chart = null;

  connect() {
    console.log("Chart controller connected");
    console.log("Chart Type:", this.typeValue);
    console.log("Chart Data:", this.dataValue);
    console.log("Chart Options:", this.optionsValue);

    // Ensure we have the canvas target and data before proceeding
    if (!this.hasCanvasTarget || !this.dataValue || !this.typeValue) {
      console.error(
        "Chart controller missing canvas target, data-value, or type-value.",
      );
      return;
    }

    this.renderChart();
  }

  disconnect() {
    // Destroy the chart instance when the controller disconnects
    // to prevent memory leaks and issues with Turbo navigation
    if (this.chart) {
      console.log("Destroying chart");
      this.chart.destroy();
      this.chart = null;
    }
  }

  renderChart() {
    // Get the canvas context
    const ctx = this.canvasTarget.getContext("2d");

    // Create the new Chart.js instance
    this.chart = new Chart(ctx, {
      type: this.typeValue, // Use the type passed from the HTML
      data: this.dataValue, // Use the data object passed from the HTML
      options: this.optionsValue, // Use the options passed from the HTML
    });
  }

  // Optional: If data/options values change, re-render the chart
  dataValueChanged() {
    this.updateChart();
  }

  optionsValueChanged() {
    this.updateChart();
  }

  typeValueChanged() {
    // Changing type usually requires destroying and re-creating
    this.disconnect(); // Destroy existing chart
    this.renderChart(); // Render new one
  }

  updateChart() {
    if (!this.chart) {
      this.renderChart(); // Render if it doesn't exist yet
      return;
    }

    // Update existing chart data and options, then redraw
    this.chart.data = this.dataValue;
    this.chart.options = this.optionsValue;
    this.chart.update();
    console.log("Chart updated");
  }
}
