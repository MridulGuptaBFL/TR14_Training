import { LightningElement } from 'lwc';
export default class ChildShape extends LightningElement {
  shapes = ['square', 'circle', 'triangle', 'pentagon'];

  handleShapeClick(event) {
    const selected = event.currentTarget.dataset.shape;
    this.dispatchEvent(new CustomEvent('shapeselected', { detail: selected }));
  }
}