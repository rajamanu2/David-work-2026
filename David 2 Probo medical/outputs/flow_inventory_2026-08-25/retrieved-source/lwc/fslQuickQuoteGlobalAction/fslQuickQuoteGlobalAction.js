import { LightningElement } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";

export default class FslGlobalFlowLauncher extends LightningElement {
  started = false;

  renderedCallback() {
    if (this.started) return;
    this.started = true;

    const flow = this.template.querySelector("lightning-flow");

    // No input variables at all
    flow.startFlow("Test_Flow");
  }

  handleStatusChange(event) {
    const status = event.detail.status;
    if (status === "FINISHED" || status === "FINISHED_SCREEN") {
      this.dispatchEvent(new CloseActionScreenEvent());
    }
  }
}