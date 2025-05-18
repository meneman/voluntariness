// app/javascript/controllers/chart_controller.js
import { Controller } from "@hotwired/stimulus";
import Chart from "chart.js/auto"; // Use "/auto" to register all controllers, scales, etc.

export default class extends Controller {
  // Define a target for the canvas element where the chart will be drawn
 

  // Define values to receive data, type, and options from the HTML
  // Stimulus automatically parses JSON strings passed to -value attributes
  static values = {
    type: String, // e.g., 'line', 'bar', 'pie'
    data: Object, // The data structure for Chart.js { labels: [], datasets: [] }
    height: Number,
    options: { type: Object, default: {} }, // Optional Chart.js options
  };


  initialize() {
    this.chart = null
    const newCanvas = document.createElement('canvas');
    const randomId = `canvas-${crypto.randomUUID()}`;
    newCanvas.id = randomId; 
    newCanvas.style.height = `${this.heightValue}px`; // Set CSS height 
    newCanvas.height = this.heightValue; // Set canvas height property (needs to be a number)

    this.element.appendChild(newCanvas);
    this.canvasContext =  newCanvas.getContext('2d');
  }

  connect() {


    // Ensure we have the canvas target and data before proceeding
    if ( !this.dataValue || !this.typeValue) {
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

    Chart.defaults.color = '#E0E0E0'; // Light gray for text (good contrast)
    Chart.defaults.borderColor = '#64B5F6'; // Lighter, less saturated blue for borders/lines
    Chart.defaults.backgroundColor = 'rgba(100, 181, 246, 0.5)'; // Semi-transparent version of the border color for fills

    this.chart = new Chart(this.canvasContext, {
      type: this.typeValue, // Use the type passed from the HTML
      data: this.dataValue, // Use the data object passed from the HTML
      options: this.optionsValue, // Use the options passed from the HTML
    });
    console.log(this.chart)
  }

  // // Optional: If data/options values change, re-render the chart
  // dataValueChanged() {
  //   this.updateChart();
  // }

  // optionsValueChanged() {
  //   this.updateChart();
  // }

  // typeValueChanged() {
  //   // Changing type usually requires destroying and re-creating
  //   this.disconnect(); // Destroy existing chart
  //   this.renderChart(); // Render new one
  // }

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
