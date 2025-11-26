import { LightningElement, track } from 'lwc';

export default class ChildColor extends LightningElement {
  @track colorList = [];

  connectedCallback() {
    // Predefined colors with visible labels and inline style
    const colors = [
      { label: 'White', value: '#ffffff' },
      { label: 'Light Red', value: '#ff6666' },
      { label: 'Dark Red', value: '#b30000' },
      { label: 'Sky Blue', value: '#66ccff' },
      { label: 'Yellow', value: '#ffcc00' },
      { label: 'Lime Green', value: '#66ff66' }
    ];
    this.colorList = colors.map(c => ({
      ...c,
      style: `background-color: ${c.value};`
    }));
  }

  handleColorClick(event) {
    const selected = event.currentTarget.dataset.color;
    this.dispatchEvent(new CustomEvent('colorselected', { detail: selected }));
  }
}