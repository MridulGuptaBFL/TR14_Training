import { LightningElement, track } from 'lwc';
export default class ParentComponent extends LightningElement {
  @track selectedShape = '';
  @track selectedColor = '';

  handleShapeSelection(event) {
    this.selectedShape = event.detail;
    // this.selectedColor = ''; // Reset color when new shape selected
  }

  handleColorSelection(event) {
    this.selectedColor = event.detail;
  }

  get outputClass() {
    return `shape ${this.selectedShape} animate-shape`;
  }

  get shapeStyle() {
    if (this.selectedShape === 'triangle') {
      // Triangle uses border-bottom for color
      return `border-bottom-color: ${this.selectedColor};`;
    }
    return `background-color: ${this.selectedColor};`;
  }

  get selectedColorLabel() {
    if (!this.selectedColor) return '';
    // Convert color hex to name for display (basic)
    const colorMap = {
      '#ffffff': 'White',
      '#ff6666': 'Light Red',
      '#b30000': 'Dark Red',
      '#66ccff': 'Sky Blue',
      '#ffcc00': 'Yellow',
      '#66ff66': 'Lime Green'
    };
    return colorMap[this.selectedColor] || this.selectedColor;
  }
}