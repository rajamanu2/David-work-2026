import { LightningElement, api } from 'lwc';

export default class FslWorkOrderCard extends LightningElement {
    @api appt;

    renderedCallback() {
        const select = this.template.querySelector('select[name="visitSelector"]');
        if (select && this.appt?.selectedVisitValue != null) {
            select.value = this.appt.selectedVisitValue;
        }
    }
    @api variant; // 'reduced' for list tab, 'recent' for recent tab, 'pm' for PM tab
    @api isCrewMode;
    @api showReadyForCloseAction;
    @api userTimeZoneId;

    // ---- Variant-driven getters ----

    get showBreakAfterDescription() {
        return this.variant !== 'reduced';
    }

    get showCardMeta() {
        return this.variant === 'reduced';
    }

    get showServiceSite() {
        return this.variant !== 'pm';
    }

    /**
     * List tab (reduced) uses appt.showWorkTypePill guard;
     * PM tab always shows the work type span unconditionally.
     * showWorkTypePillConditionally = true means we apply the appt.showWorkTypePill guard.
     */
    get showWorkTypePillConditionally() {
        return this.variant !== 'pm';
    }

    /**
     * List tab (reduced) uses a no-label edit button with class sfs-po-edit-button.
     * Recent and PM tabs use a labeled button with class sfs-po-edit.
     */
    get showReducedPoEditButton() {
        return this.variant === 'reduced';
    }

    get scheduleOnCalendarLabel() {
        return (this.appt && this.appt.scheduleOnCalendarLabel) || 'Schedule on Calendar';
    }

    get appointmentDetails() {
        return (this.appt && (
            this.appt.description ||
            this.appt.serviceAppointmentSubject ||
            this.appt.workOrderSubject
        )) || null;
    }

    // ---- Event dispatcher helpers ----

    handleVisitSelectionChange(event) {
        const workOrderId = event?.currentTarget?.dataset?.workOrderId;
        const value = event?.detail?.value !== undefined
            ? event.detail.value
            : event?.target?.value;
        this.dispatchEvent(new CustomEvent('visitselectionchange', {
            bubbles: true,
            detail: { workOrderId, value }
        }));
    }

    handleMoreActionsSelect(event) {
        event.stopPropagation();
        const action = event.detail.value;
        const appointmentId = event.currentTarget.dataset.id;
        const workOrderId = event.currentTarget.dataset.woid;
        this.dispatchEvent(new CustomEvent('moreactionsselect', {
            bubbles: true,
            detail: { action, appointmentId, workOrderId }
        }));
    }

    handleOpenAccountModal(event) {
        const dataset = event?.currentTarget?.dataset || {};
        this.dispatchEvent(new CustomEvent('openaccountmodal', {
            bubbles: true,
            detail: {
                id: dataset.id || null,
                woid: dataset.woid || null,
                appointmentId: dataset.appointmentId || null
            }
        }));
    }

    handlePoNumberDraftChange(event) {
        const value = event.detail?.value;
        const workOrderId = event.currentTarget?.dataset?.woid;
        this.dispatchEvent(new CustomEvent('ponumberdraftchange', {
            bubbles: true,
            detail: { value, woid: workOrderId }
        }));
    }

    handlePoNumberKeydown(event) {
        const key = event.key;
        const workOrderId = event.currentTarget?.dataset?.woid;
        this.dispatchEvent(new CustomEvent('ponumberkeydown', {
            bubbles: true,
            detail: { key, woid: workOrderId }
        }));
    }

    handlePoNumberSave(event) {
        const workOrderId = event?.currentTarget?.dataset?.woid;
        this.dispatchEvent(new CustomEvent('ponumbersave', {
            bubbles: true,
            detail: { woid: workOrderId }
        }));
    }

    handlePoNumberCancel(event) {
        const workOrderId = event?.currentTarget?.dataset?.woid;
        this.dispatchEvent(new CustomEvent('ponumbercancel', {
            bubbles: true,
            detail: { woid: workOrderId }
        }));
    }

    handlePoNumberEdit(event) {
        const workOrderId = event.currentTarget?.dataset?.woid;
        this.dispatchEvent(new CustomEvent('ponumberedit', {
            bubbles: true,
            detail: { woid: workOrderId }
        }));
    }

    handleListInfoClick(event) {
        const cardId = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('listinfoclick', {
            bubbles: true,
            detail: { id: cardId }
        }));
    }

    handleQuoteAttachmentClick(event) {
        event.preventDefault();
        const cardId = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('quoteattachmentclick', {
            bubbles: true,
            detail: { id: cardId }
        }));
    }

    handleMarkQuoteSent(event) {
        const workOrderId = event.target.dataset.woid;
        this.dispatchEvent(new CustomEvent('markquotesent', {
            bubbles: true,
            detail: { woid: workOrderId }
        }));
    }

    handleMarkRepairSent(event) {
        const workOrderId = event.target.dataset.woid;
        this.dispatchEvent(new CustomEvent('markrepairsent', {
            bubbles: true,
            detail: { woid: workOrderId }
        }));
    }

    handleMarkPoAttached(event) {
        const workOrderId = event.target.dataset.woid;
        this.dispatchEvent(new CustomEvent('markpoattached', {
            bubbles: true,
            detail: { woid: workOrderId }
        }));
    }

    handleCancelSale(event) {
        const workOrderId = event.target.dataset.woid;
        this.dispatchEvent(new CustomEvent('cancelsale', {
            bubbles: true,
            detail: { woid: workOrderId }
        }));
    }

    handleApproveRepair(event) {
        const workOrderId = event.target.dataset.woid;
        this.dispatchEvent(new CustomEvent('approverepair', {
            bubbles: true,
            detail: { woid: workOrderId }
        }));
    }

    handleApproveExchange(event) {
        const workOrderId = event.target.dataset.woid;
        this.dispatchEvent(new CustomEvent('approveexchange', {
            bubbles: true,
            detail: { woid: workOrderId }
        }));
    }

    handleDeclineRepair(event) {
        const workOrderId = event.target.dataset.woid;
        this.dispatchEvent(new CustomEvent('declinerepair', {
            bubbles: true,
            detail: { woid: workOrderId }
        }));
    }

    handleConfirmShipping(event) {
        const workOrderId = event.target.dataset.woid;
        this.dispatchEvent(new CustomEvent('confirmshipping', {
            bubbles: true,
            detail: { woid: workOrderId }
        }));
    }

    handleOpenReporterContactModal(event) {
        const dataset = event?.currentTarget?.dataset || {};
        this.dispatchEvent(new CustomEvent('openreportercontactmodal', {
            bubbles: true,
            detail: {
                id: dataset.id || null,
                woid: dataset.woid || null,
                appointmentId: dataset.appointmentId || null
            }
        }));
    }

    handleOpenAddressModal(event) {
        const dataset = event?.currentTarget?.dataset || {};
        this.dispatchEvent(new CustomEvent('openaddressmodal', {
            bubbles: true,
            detail: {
                id: dataset.id || null,
                woid: dataset.woid || null,
                appointmentId: dataset.appointmentId || null
            }
        }));
    }

    handleServiceSiteNameEdit(event) {
        const workOrderId = event.currentTarget?.dataset?.woid;
        this.dispatchEvent(new CustomEvent('servicesiteedit', {
            bubbles: true,
            detail: { woid: workOrderId }
        }));
    }

    handleServiceSiteNameCancel(event) {
        const workOrderId = event.currentTarget?.dataset?.woid;
        this.dispatchEvent(new CustomEvent('servicesitecancel', {
            bubbles: true,
            detail: { woid: workOrderId }
        }));
    }

    handleServiceSiteNameDraftChange(event) {
        const value = event.detail?.value;
        const workOrderId = event.currentTarget?.dataset?.woid;
        this.dispatchEvent(new CustomEvent('servicesitedraftchange', {
            bubbles: true,
            detail: { value, woid: workOrderId }
        }));
    }

    handleServiceSiteNameKeydown(event) {
        const key = event.key;
        const workOrderId = event.currentTarget?.dataset?.woid;
        this.dispatchEvent(new CustomEvent('servicesitekeydown', {
            bubbles: true,
            detail: { key, woid: workOrderId }
        }));
    }

    handleServiceSiteNameSave(event) {
        const workOrderId = event.currentTarget?.dataset?.woid;
        this.dispatchEvent(new CustomEvent('servicesitesave', {
            bubbles: true,
            detail: { woid: workOrderId }
        }));
    }

    handleOpenShippingAddressModal(event) {
        const dataset = event?.currentTarget?.dataset || {};
        this.dispatchEvent(new CustomEvent('openshippingaddressmodal', {
            bubbles: true,
            detail: {
                id: dataset.id || null,
                woid: dataset.woid || null,
                appointmentId: dataset.appointmentId || null
            }
        }));
    }

    handleCopyTracking(event) {
        const tracking = event?.currentTarget?.dataset?.tracking ||
            event?.target?.dataset?.tracking || null;
        this.dispatchEvent(new CustomEvent('copytracking', {
            bubbles: true,
            detail: { tracking }
        }));
    }

    handleToggleListDetails(event) {
        const id = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('togglelistdetails', {
            bubbles: true,
            detail: { id }
        }));
    }

    handleToggleQuoteLineItems(event) {
        const cardId = event?.currentTarget?.dataset?.cardId;
        this.dispatchEvent(new CustomEvent('togglequotelineitems', {
            bubbles: true,
            detail: { cardId }
        }));
    }

    handleScheduleActionClick(event) {
        const isBlocked = event?.currentTarget?.dataset?.blocked === 'true' ||
            event?.currentTarget?.dataset?.blocked === true;
        const cardId = event?.currentTarget?.dataset?.id || null;
        this.dispatchEvent(new CustomEvent('scheduleactionclick', {
            bubbles: true,
            detail: { isBlocked, id: cardId, targetIsCurrentTarget: event.target === event.currentTarget }
        }));
    }

    handleToggleQuickSchedulePanel(event) {
        const cardId = event?.currentTarget?.dataset?.id;
        this.dispatchEvent(new CustomEvent('togglequickschedulepanel', {
            bubbles: true,
            detail: { id: cardId }
        }));
    }

    handleScheduleOnCalendar(event) {
        const cardId = event?.currentTarget?.dataset?.id || null;
        this.dispatchEvent(new CustomEvent('scheduleoncalendar', {
            bubbles: true,
            detail: { id: cardId }
        }));
    }

    handleQuickScheduleChange(event) {
        const cardId = event.target.dataset.id;
        const value = event.target.value;
        this.dispatchEvent(new CustomEvent('quickschedulechange', {
            bubbles: true,
            detail: { id: cardId, value }
        }));
    }

    handleQuickSchedule(event) {
        const cardId = event?.currentTarget?.dataset?.id || null;
        this.dispatchEvent(new CustomEvent('quickschedule', {
            bubbles: true,
            detail: { id: cardId }
        }));
    }

    handleCrewMemberChange(event) {
        const id = event.target.dataset.id;
        const value = event.detail.value;
        this.dispatchEvent(new CustomEvent('crewmemberchange', {
            bubbles: true,
            detail: { id, value }
        }));
    }

    handleAssignToCrewMember(event) {
        const id = event.target.dataset.id;
        this.dispatchEvent(new CustomEvent('assigntocrewmember', {
            bubbles: true,
            detail: { id }
        }));
    }
}
