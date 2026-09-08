import { LightningElement, track } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { NavigationMixin } from 'lightning/navigation';
import getMyAppointmentsOnlineScoped from '@salesforce/apex/FslTechnicianOnlineController.getMyAppointmentsOnlineScoped';
import getHistoryItems from '@salesforce/apex/FslTechnicianOnlineController.getHistoryItems';
import rescheduleAppointment from '@salesforce/apex/FslTechnicianOnlineController.rescheduleAppointment';
import assignCrewAppointment from '@salesforce/apex/FslTechnicianOnlineController.assignCrewAppointment';
import createAppointmentForWorkOrder from '@salesforce/apex/FslTechnicianOnlineController.createAppointmentForWorkOrder';
import updateAppointmentEnd from '@salesforce/apex/FslTechnicianOnlineController.updateAppointmentEnd';
import unassignAppointment from '@salesforce/apex/FslTechnicianOnlineController.unassignAppointment';
import getTerritoryResources from '@salesforce/apex/FslTechnicianOnlineController.getTerritoryResources';
import createEngineerTransferRequest from '@salesforce/apex/FslTechnicianOnlineController.createEngineerTransferRequest';
import acceptEngineerTransferRequest from '@salesforce/apex/FslTechnicianOnlineController.acceptEngineerTransferRequest';
import rejectEngineerTransferRequest from '@salesforce/apex/FslTechnicianOnlineController.rejectEngineerTransferRequest';
import cancelWorkOrder from '@salesforce/apex/FslTechnicianOnlineController.cancelWorkOrder';
import markWorkOrderQuoteSent from '@salesforce/apex/FslTechnicianOnlineController.markWorkOrderQuoteSent';
import markWorkOrderPendingApproval from '@salesforce/apex/FslTechnicianOnlineController.markWorkOrderPendingApproval';
import markWorkOrderPoAttached from '@salesforce/apex/FslTechnicianOnlineController.markWorkOrderPoAttached';
import markWorkOrderWaitingForPo from '@salesforce/apex/FslTechnicianOnlineController.markWorkOrderWaitingForPo';
import markWorkOrderCancelSale from '@salesforce/apex/FslTechnicianOnlineController.markWorkOrderCancelSale';
import markWorkOrderReadyForClose from '@salesforce/apex/FslTechnicianOnlineController.markWorkOrderReadyForClose';
import markWorkOrderRepairApproved from '@salesforce/apex/FslTechnicianOnlineController.markWorkOrderRepairApproved';
import markWorkOrderRepairDeclined from '@salesforce/apex/FslTechnicianOnlineController.markWorkOrderRepairDeclined';
import markWorkOrderExchangeApproved from '@salesforce/apex/FslTechnicianOnlineController.markWorkOrderExchangeApproved';
import markWorkOrderConfirmedShipping from '@salesforce/apex/FslTechnicianOnlineController.markWorkOrderConfirmedShipping';
import submitCustomWorkOrderRequest from '@salesforce/apex/FslTechnicianOnlineController.submitCustomWorkOrderRequest';
import getWorkOrderLineItemsForReturn from '@salesforce/apex/FslTechnicianOnlineController.getWorkOrderLineItemsForReturn';
import markWorkOrderItemsForReturn from '@salesforce/apex/FslTechnicianOnlineController.markWorkOrderItemsForReturn';
import getDeletedWorkOrderLineItems from '@salesforce/apex/FslTechnicianOnlineController.getDeletedWorkOrderLineItems';
import undeleteWorkOrderLineItems from '@salesforce/apex/FslTechnicianOnlineController.undeleteWorkOrderLineItems';
import updateResourceAbsence from '@salesforce/apex/FslTechnicianOnlineController.updateResourceAbsence';
import deleteResourceAbsence from '@salesforce/apex/FslTechnicianOnlineController.deleteResourceAbsence';
import updateWorkOrderAddress from '@salesforce/apex/FslTechnicianOnlineController.updateWorkOrderAddress';
import updateWorkOrderShippingAddress from '@salesforce/apex/FslTechnicianOnlineController.updateWorkOrderShippingAddress';
import getUserAddressBook from '@salesforce/apex/FslTechnicianOnlineController.getUserAddressBook';
import getStateAbbreviation from '@salesforce/apex/FslTechnicianOnlineController.getStateAbbreviation';
import updateWorkOrderAccountName from '@salesforce/apex/FslTechnicianOnlineController.updateWorkOrderAccountName';
import updateWorkOrderReporterContactInfo from '@salesforce/apex/FslTechnicianOnlineController.updateWorkOrderReporterContactInfo';
import updateWorkOrderPoNumber from '@salesforce/apex/FslTechnicianOnlineController.updateWorkOrderPoNumber';
import updateWorkOrderServiceSiteName from '@salesforce/apex/FslTechnicianOnlineController.updateWorkOrderServiceSiteName';
import getRmasForCurrentEngineer from '@salesforce/apex/FslTechnicianOnlineController.getRmasForCurrentEngineer';
import updateEngineerRmaTracking from '@salesforce/apex/FslTechnicianOnlineController.updateEngineerRmaTracking';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const ACTION_STATUS_ALERT_MODES = new Set([
    'partsProbeShipped',
    'quoteAttached',
    'quoteSent',
    'confirmShipping',
    'waitingForPo',
    'generateFsr',
    'reGenerateFsr',
    'revisitPending',
    'probePendingApproval',
    'probeRepairDeclined'
]);
const ACTION_STATUS_FILTER_MODES = Array.from(ACTION_STATUS_ALERT_MODES);

export default class FslHello extends NavigationMixin(LightningElement) {
    @track appointments = [];
    @track absences = [];
    @track historyItems = [];
    @track historySearchFilter = '';
    @track historySearchInput = '';
    @track historyLoaded = false;
    @track isHistoryLoading = false;
    historySearchDebounceMs = 300;
    _historySearchDebounceTimeout = null;
    @track debugInfo = {};
    @track calendarDays = [];
    @track selectedAppointment = null;
    @track selectedAbsence = null;
    @track selectedVisitByWorkOrder = {};
    get hasVisibleAppointments() {
        return this.visibleAppointments.length > 0;
    }

    getServiceAppointmentDisplayTitle(appt) {
        if (!appt) {
            return 'Appointment';
        }

        const details =
            appt.description ||
            appt.serviceAppointmentSubject ||
            appt.workOrderSubject ||
            'Appointment';

        return appt.appointmentNumber
            ? `${appt.appointmentNumber} — ${details}`
            : details;
    }
    currentUserId = null;
    activeUserId = null;
    viewingUserName = 'Me';
    isManager = false;
    managerTeam = [];
    selectedManagerUserId = null;
    selectedManagerUserName = '';

    // Unscheduled work orders (tray)
    @track unscheduledWorkOrders = [];
    @track unscheduledSortValue = 'accountAsc';
    @track preventativeMaintenanceSortValue = 'nextServiceDateAsc';
    @track transferRequests = [];
    @track submittedTransferRequests = [];
    pullTrayOpen = false;
    pullTrayPeek = false;
    _trayWasExpandedBeforeDrag = false;
    _trayOpenBeforeDrag = false;
    isDesktopFormFactor = FORM_FACTOR === 'Large';
    activeTab = 'list';
    preventativeMaintenanceTab = 'unscheduled';
    preventativeMaintenanceUnscheduledTab = 'next30';
    isCalendarTabActive = false;
    lastKnownActiveTab = 'list';

    // RMA tab
    @track rmaItems = [];
    @track rmaTrackingDraft = {};
    @track rmaTrackingEditMode = {};
    @track rmaSearchInput = '';
    @track rmaSearchFilter = '';
    @track rmaExcludeTracked = false;
    rmaTrackingSaving = {};
    isRmaLoading = false;
    rmaLoaded = false;
    _rmaSearchDebounceTimeout = null;

    // Global "now" line state
    showNowLine = false;
    nowLineStyle = '';

    // requestAnimationFrame handle for positioning the "now" line
    _nowLineFrame = null;

    isLoading = false;
    isOffline = false;
    loadedDataScope = null;

    // Center timeline on "today" only when explicitly requested
    _needsCenterOnToday = false;

    // Salesforce user time-zone
    userTimeZoneId = null;
    userTimeZoneShort = null;

    // Calendar config
    daysToShow = 14;
    timelineStartDate;
    weekStartDate;
    calendarStartHour = 0;
    calendarEndHour = 24;

    // Drag and drop state for calendar
    dragMode = null;              // 'event', 'wo', or 'resize'
    draggingEventId = null;
    draggingWorkOrderId = null;
    dragStartDayIndex = null;
    dragCurrentDayIndex = null;
    dragStartLocal = null;
    dragStartClientX = null;
    dragStartClientY = null;
    dragDayWidth = null;
    dragDayBodyTop = null; // screen Y of the top of the day body (for time alignment)
    dragDayBodyHeight = null;
    dragPreviewLocal = null;
    dragStartEndLocal = null;
    dragPreviewDurationHours = null;
    dragDurationHours = null;
    dragHasMoved = false;
    dragGhostPointerOffsetY = 0;
    defaultWorkOrderDurationHours = 6;
    quickScheduleSelections = {};
    quickScheduleExpanded = {};
    collapsedDayGroups = {};
    showTrayCancelZone = false;
    isHoveringCancelZone = false;
    dragRequiresExplicitConfirmation = true;
    isAwaitingScheduleConfirmation = false;
    pendingSchedulePlacement = null;
    schedulePreviewCardId = null;
    schedulePreviewListMode = null;

    // Reschedule with another tech modal
    isRescheduleModalOpen = false;
    rescheduleOptions = [];
    rescheduleSelection = null;
    rescheduleWorkOrderId = null;
    rescheduleLoading = false;

    // Unschedule confirmation modal
    isUnassignModalOpen = false;
    unassignTarget = null;

    // Transfer request rejection modal
    isRejectModalOpen = false;
    rejectReason = '';
    rejectRequestId = null;

    // Cancel work order modal
    isCancelModalOpen = false;
    cancelReason = '';
    cancelWorkOrderId = null;
    // Cancel sale modal
    isCancelSaleModalOpen = false;
    cancelSaleNotes = '';
    cancelSaleWorkOrderId = null;
    // Repair approval type modal
    isRepairApprovalModalOpen = false;
    repairApprovalWorkOrderId = null;
    // Ready for close modal
    isReadyForCloseModalOpen = false;
    readyForCloseNotes = '';
    readyForCloseWorkOrderId = null;

    // Custom request modal
    isCustomRequestModalOpen = false;
    customRequestNotes = '';
    customRequestWorkOrderId = null;

    // Mark items for return modal
    isMarkForReturnModalOpen = false;
    markForReturnWorkOrderId = null;

    // Deleted line items (request history) modal
    isDeletedWoliModalOpen = false;
    deletedWoliWorkOrderId = null;
    @track deletedWoliItems = [];
    isDeletedWoliLoading = false;
    deletedWoliSelectedIds = [];
    markForReturnStep = 1;
    @track markForReturnLineItems = [];
    @track markForReturnSelectedIds = [];
    isMarkForReturnLoading = false;

    // PO number required modal
    isPoRequiredModalOpen = false;
    poRequiredWorkOrderId = null;
    poRequiredActionLabel = '';
    // PO number edit modal
    isPoNumberModalOpen = false;
    poNumberSaving = false;
    poNumberModalWorkOrderId = null;
    poNumberModalValue = '';
    _poNumberModalDebounceTimer = null;
    _poNumberModalPending = null;
    _poNumberInlineDebounceTimer = null;
    _poNumberInlinePending = null;
    isServiceSiteModalOpen = false;
    serviceSiteModalWorkOrderId = null;
    serviceSiteModalValue = '';
    _serviceSiteModalDebounceTimer = null;
    _serviceSiteModalPending = null;

    // Global error capture handlers
    _boundOnGlobalError = null;
    _boundOnUnhandledRejection = null;
    _hasRegisteredErrorHandlers = false;

    // Long press to start drag
    dragLongPressTimer = null;
    dragHoldDelayMs = 600;
    isPressingForDrag = false;
    _pendingDrag = null;          // holds data until long press triggers
    _boundGlobalPointerMove = null;
    _boundGlobalPointerEnd = null;

    // Auto-scroll while dragging near viewport edges
    _autoScrollPoint = null;
    _autoScrollFrame = null;

    // Anchor drag ghost to calendar while awaiting confirmation
    _boundGhostAnchorUpdater = null;
    _ghostAnchorFrame = null;

    // Remember last placement so a quick tap on the ghost can restore it
    _pendingRegrabPlacement = null;

    // Floating ghost under the finger
    // Floating ghost under the finger (clone of the event)
    dragGhostVisible = false;
    dragGhostX = 0;
    dragGhostY = 0;
    dragGhostAnchoredToCalendar = false;
    dragGhostWidth = 0;
    dragGhostHeight = 0;
    dragGhostTitle = '';
    dragGhostTime = '';
    dragGhostTypeClass = ''; // sfs-event-pm / sfs-event-breakfix / etc

    // 'timeline' or 'week'
    calendarMode = 'timeline';
    isCalendarPanMode = false;
    // list sub-modes: 'my', 'needQuote', 'poRequested', 'waitingForPo', 'quoteSent', 'readyToShip', 'confirmShipping', 'quotes', 'quoteAttached', 'crew', 'partsReady', 'fulfilling'
    listMode = 'unscheduled';
    recentMode = 'created';
    historyMode = 'nonPreventative';
    listModePrimaryTab = 'all';
    listOpportunityType = 'all';
    listVisibleCount = 10;
    _listSentinelObserver = null;
    _listSentinelObservedEl = null;
    workOrderNumberFilter = '';
    hasInteractedWithWorkOrderNumberFilter = false;
    filtersOpen = false;
    showSearchFieldGuide = false;
    isActionStatusFocusEnabled = false;

    quickQuoteFlowApiName = 'FSL_Action_Quick_Quote_2';
    quickQuoteQuickActionApiName = 'QuickCreateQuote';
    quickQuoteFlowExtensionName = '';
    updateCommentsFlowApiName = 'CloseOutWorkOrder';
    // Address modal state
    isAddressModalOpen = false;
    addressSaving = false;
    addressModalWorkOrderId = null;
    addressModalAppointmentId = null;
    addressModalCardId = null;
    addressMode = 'saved';
    addressSelection = '';
    addressForm = {
        street: '',
        city: '',
        state: '',
        country: 'United States',
        postalCode: ''
    };
    addressHelpCardId = null;
    _addressHelpTimeout = null;
    _addressInputDebounceTimer = null;
    _addressFormPending = null;
    // Shipping address modal state
    isShippingAddressModalOpen = false;
    shippingAddressSaving = false;
    shippingAddressModalWorkOrderId = null;
    shippingAddressModalAppointmentId = null;
    shippingAddressModalCardId = null;
    shippingAddressMode = 'saved';
    shippingAddressOptions = [];
    shippingAddressBook = [];
    shippingAddressSelection = '';
    shippingAddressForm = {
        attn: '',
        shippingSiteName: '',
        street: '',
        city: '',
        state: '',
        country: 'United States',
        postalCode: ''
    };
    _shippingAddressLoadPromise = null;
    _shippingAddressInputDebounceTimer = null;
    _shippingAddressFormPending = null;
    // Repair decline confirmation modal state
    isRepairDeclineConfirmModalOpen = false;
    repairDeclineConfirmWorkOrderId = null;
    repairDeclineConfirmRecord = null;
    repairDeclineShippingEditPending = false;
    // Account modal state
    isAccountModalOpen = false;
    accountSaving = false;
    accountModalWorkOrderId = null;
    accountModalAppointmentId = null;
    accountModalCardId = null;
    accountForm = {
        name: ''
    };
    // Reporter contact modal state
    isReporterContactModalOpen = false;
    reporterContactSaving = false;
    reporterContactModalWorkOrderId = null;
    reporterContactModalAppointmentId = null;
    reporterContactModalCardId = null;
    reporterContactForm = {
        info: ''
    };

    quoteStatuses = [
        'Action Needed',
        'Quote and Ship',
        'PO Requested',
        'Quote Sent',
        'Quote Attached',
        'Ready to Ship',
        'Pending Shipment',
        'Parts/Probe Shipped'
    ];
    probeRepairStageOptions = [
        {
            value: 'probeProposalPriceQuote',
            label: 'Proposal/Price Quote',
            stage: 'Proposal/Price Quote'
        },
        {
            value: 'probeRepairEvaluation',
            label: 'Repair Evaluation',
            stage: 'Repair Evaluation'
        },
        {
            value: 'probeEvaluationComplete',
            label: 'Evaluation Complete',
            stage: 'Evaluation Complete'
        },
        {
            value: 'probePendingApproval',
            label: 'Pending Approval',
            stage: 'Pending Approval'
        }
    ];
    journeyMainFlow = [
        'New',
        'In Progress',
        'Generate FSR',
        'Ready for Close'
    ];
    journeyTerminalStatuses = [
        'Closed',
        'Completed WO',
        'Completed Work Order',
        'Cannot Complete',
        'Canceled'
    ];
    journeyDetours = {
        quote: {
            label: 'Quote path',
            steps: [
                'Action Needed',
                'Quote Attached',
                'Quote Sent',
                'PO Requested',
                'Ready to Ship',
                'Pending Shipment',
                'Parts/Probe Shipped'
            ]
        },
        parts: {
            label: 'Parts path',
            steps: [
                'Parts Requested',
                'PO Requested',
                'Ready to Ship',
                'Pending Shipment',
                'Parts/Probe Shipped'
            ]
        }
    };
    quoteLineItemsExpanded = {};
    journeyExpanded = {};

    // For auto-centering timeline
    hasAutoCentered = false;
    todayDayIndex = null;
    _centerTimeout;

    // Detail bottom sheet animation
    isDetailClosing = false;
    _closeTimeout;
    isAbsenceDetailClosing = false;
    _absenceCloseTimeout;

    // ======= GETTERS =======

    get hasAppointments() {
        const apptCount = this.appointments ? this.appointments.length : 0;
        const absenceCount = this.absences ? this.absences.length : 0;
        return apptCount + absenceCount > 0;
    }

    get normalizedWorkOrderNumberFilter() {
        return (this.workOrderNumberFilter || '').trim().toLowerCase();
    }

    get hasWorkOrderNumberFilter() {
        return this.normalizedWorkOrderNumberFilter.length > 0;
    }

    get filterToggleClass() {
        const classes = ['sfs-filter-toggle'];

        if (this.filtersOpen) {
            classes.push('sfs-filter-toggle_active');
        }

        if (this.hasWorkOrderNumberFilter) {
            classes.push('sfs-filter-toggle_has-value');
        }

        return classes.join(' ');
    }

    get actionStatusFocusToggleClass() {
        const classes = ['sfs-action-focus-toggle'];

        if (this.isActionStatusFocusEnabled) {
            classes.push('sfs-action-focus-toggle_active');
        }

        return classes.join(' ');
    }

    get showActionStatusFocusBanner() {
        return this.isActionStatusFocusEnabled;
    }

    get actionStatusFocusCount() {
        return this.getActionStatusModeOptions().reduce(
            (total, option) =>
                total +
                this.getListModeCountForPrimaryTab(
                    option.value,
                    this.listModePrimaryTab
                ),
            0
        );
    }

    get actionStatusFocusMessage() {
        const count = this.actionStatusFocusCount;
        const label = count === 1 ? 'work order' : 'work orders';

        return `Engineer action focus is on — showing ${count} ${label} currently in your court.`;
    }

    get isMyMode() {
        return this.listMode === 'my';
    }

    get isListTabActive() {
        return this.activeTab === 'list';
    }

    get isRecentTabActive() {
        return this.activeTab === 'recent';
    }

    get isHistoryTabActive() {
        return this.activeTab === 'history';
    }

    get isRmaTabActive() {
        return this.activeTab === 'rma';
    }

    get isPreventativeMaintenanceTabActive() {
        return this.activeTab === 'preventativeMaintenance';
    }

    get isManagerTabActive() {
        return this.activeTab === 'manager';
    }

    get isManagerTabVisible() {
        return this.isManager && this.isManagerTabActive;
    }

    get listTabButtonClass() {
        return this.getTabButtonClass('list');
    }

    get recentTabButtonClass() {
        return this.getTabButtonClass('recent');
    }

    get historyTabButtonClass() {
        return this.getTabButtonClass('history');
    }

    get preventativeMaintenanceTabButtonClass() {
        return this.getTabButtonClass('preventativeMaintenance');
    }

    get calendarTabButtonClass() {
        return this.getTabButtonClass('calendar');
    }

    get rmaTabButtonClass() {
        return this.getTabButtonClass('rma');
    }

    get managerTabButtonClass() {
        return this.getTabButtonClass('manager');
    }

    get opportunityTypeTabs() {
        const tabs = [
            { value: 'all', label: 'All' },
            { value: 'breakFix', label: 'Break-Fix / Parts Sale' },
            { value: 'probeRepair', label: 'Probe Repair' },
            { value: 'probeSale', label: 'Probe Sale' }
        ];

        return tabs.map(tab => {
            const count = this.getOpportunityTypeTotalCount(tab.value);
            return {
                ...tab,
                isActive: this.listOpportunityType === tab.value,
                className: this.getOpportunityTypeTabClass(tab.value),
                count,
                countLabel: count > 0 ? `(${count})` : '',
                countClass: 'sfs-opportunity-tab__count'
            };
        });
    }

    get preventativeMaintenanceTabs() {
        const tabs = [
            { value: 'unscheduled', label: 'Unscheduled' },
            { value: 'scheduled', label: 'Scheduled' },
            { value: 'readyForClose', label: 'Ready for Close' },
            { value: 'completed', label: 'Completed' }
        ];

        const counts = this.preventativeMaintenanceCounts;
        const unscheduledCount =
            (counts.unscheduledNext30 || 0) + (counts.unscheduledAfter30 || 0);

        return tabs.map(tab => ({
            ...tab,
            isActive: this.preventativeMaintenanceTab === tab.value,
            className: this.getPreventativeMaintenanceTabClass(tab.value),
            count:
                tab.value === 'unscheduled'
                    ? unscheduledCount
                    : counts[tab.value] || 0,
            countLabel:
                tab.value === 'unscheduled'
                    ? `(${unscheduledCount})`
                    : `(${counts[tab.value] || 0})`,
            countClass:
                tab.value === 'unscheduled' && (counts.unscheduledNext30 || 0) > 0
                    ? 'sfs-opportunity-tab__count sfs-opportunity-tab__count_alert'
                    : 'sfs-opportunity-tab__count'
        }));
    }

    get preventativeMaintenanceUnscheduledTabs() {
        const counts = this.preventativeMaintenanceCounts;
        const tabs = [
            { value: 'next30', label: 'Next 30 Days' },
            { value: 'after30', label: 'After 30 Days' }
        ];

        return tabs.map(tab => ({
            ...tab,
            isActive: this.preventativeMaintenanceUnscheduledTab === tab.value,
            className: this.getPreventativeMaintenanceUnscheduledTabClass(tab.value),
            count: tab.value === 'next30'
                ? counts.unscheduledNext30 || 0
                : counts.unscheduledAfter30 || 0,
            countLabel: tab.value === 'next30'
                ? `(${counts.unscheduledNext30 || 0})`
                : `(${counts.unscheduledAfter30 || 0})`,
            countClass:
                tab.value === 'next30'
                    ? 'sfs-opportunity-tab__count sfs-opportunity-tab__count_alert'
                    : 'sfs-opportunity-tab__count'
        }));
    }

    _activeClass(active, target, base, activeSuffix) {
        return active === target ? base + (activeSuffix || '_active') : base;
    }

    getTabButtonClass(tabValue) {
        return this._activeClass(this.activeTab, tabValue, 'sfs-tab-btn', ' sfs-tab-btn_active');
    }

    getOpportunityTypeTabClass(typeValue) {
        return this._activeClass(this.listOpportunityType, typeValue, 'sfs-opportunity-tab', ' sfs-opportunity-tab_active');
    }

    getPreventativeMaintenanceTabClass(tabValue) {
        return this._activeClass(this.preventativeMaintenanceTab, tabValue, 'sfs-opportunity-tab', ' sfs-opportunity-tab_active');
    }

    getPreventativeMaintenanceUnscheduledTabClass(tabValue) {
        return this._activeClass(this.preventativeMaintenanceUnscheduledTab, tabValue, 'sfs-pm-range-table__cell', ' sfs-pm-range-table__cell_active');
    }

    getRecentModeTabClass(tabValue) {
        return this._activeClass(this.recentMode, tabValue, 'sfs-list-mode-tabs__item', ' sfs-list-mode-tabs__item_active');
    }

    getHistoryModeTabClass(tabValue) {
        return this._activeClass(this.historyMode, tabValue, 'sfs-list-mode-tabs__item', ' sfs-list-mode-tabs__item_active');
    }

    get isPreventativeMaintenanceUnscheduledActive() {
        return this.preventativeMaintenanceTab === 'unscheduled';
    }

    get preventativeMaintenanceActiveTab() {
        if (this.preventativeMaintenanceTab === 'unscheduled') {
            return this.preventativeMaintenanceUnscheduledTab === 'after30'
                ? 'unscheduledAfter30'
                : 'unscheduledNext30';
        }

        return this.preventativeMaintenanceTab;
    }

    get isDragGhostVisible() {
        return this.dragGhostVisible;
    }

    get isDragging() {
        return !!(this.dragMode || this.isPressingForDrag);
    }

    get calendarDaysWrapperClass() {
        const classes = ['sfs-calendar-days-wrapper'];

        if (this.isCalendarPanMode) {
            classes.push('sfs-calendar-days-wrapper_pan');
        }

        if (this.isDragging) {
            classes.push('sfs-calendar-days-wrapper_dragging');
        }

        return classes.join(' ');
    }

    get calendarDaysClass() {
        return this.isCalendarPanMode
            ? 'sfs-calendar-days sfs-calendar-days_pan'
            : 'sfs-calendar-days';
    }

    get calendarPanButtonClass() {
        const base = 'sfs-calendar-pan-toggle';
        return this.isCalendarPanMode
            ? `${base} sfs-calendar-pan-toggle_active`
            : base;
    }

    get calendarPanStateLabel() {
        return this.isCalendarPanMode ? 'Panning' : 'Drag to move';
    }

    get trayCancelZoneClass() {
        return this.isHoveringCancelZone
            ? 'sfs-tray-cancel-zone sfs-tray-cancel-zone_active'
            : 'sfs-tray-cancel-zone';
    }

    get isViewingAsOther() {
        return (
            this.activeUserId &&
            this.currentUserId &&
            this.activeUserId !== this.currentUserId
        );
    }

    get viewingAsLabel() {
        return this.isViewingAsOther
            ? `Viewing as ${this.viewingUserName}`
            : 'Viewing as yourself';
    }

    get managerOptions() {
        return (this.managerTeam || []).map(m => ({
            label: m.name,
            value: m.userId
        }));
    }

    get managerApplyDisabled() {
        return !this.selectedManagerUserId;
    }

    registerGlobalDragListeners() {
        if (!this._boundGlobalPointerMove) {
            this._boundGlobalPointerMove = this.handleCalendarPointerMove.bind(this);
        }
        if (!this._boundGlobalPointerEnd) {
            this._boundGlobalPointerEnd = this.handleCalendarPointerEnd.bind(this);
        }

        window.addEventListener('mousemove', this._boundGlobalPointerMove);
        window.addEventListener('mouseup', this._boundGlobalPointerEnd);
        window.addEventListener('touchmove', this._boundGlobalPointerMove, {
            passive: false
        });
        window.addEventListener('touchend', this._boundGlobalPointerEnd);
    }

    unregisterGlobalDragListeners() {
        if (this._boundGlobalPointerMove) {
            window.removeEventListener('mousemove', this._boundGlobalPointerMove);
            window.removeEventListener('touchmove', this._boundGlobalPointerMove);
        }

        if (this._boundGlobalPointerEnd) {
            window.removeEventListener('mouseup', this._boundGlobalPointerEnd);
            window.removeEventListener('touchend', this._boundGlobalPointerEnd);
        }
    }

    updateTrayCancelHover(clientX, clientY) {
        if (!this.showTrayCancelZone || this.dragMode !== 'wo') {
            this.isHoveringCancelZone = false;
            return;
        }

        const zone = this.template.querySelector('[data-cancel-zone="true"]');
        if (!zone) {
            this.isHoveringCancelZone = false;
            return;
        }

        const rect = zone.getBoundingClientRect();
        const inside =
            clientX >= rect.left &&
            clientX <= rect.right &&
            clientY >= rect.top &&
            clientY <= rect.bottom;

        this.isHoveringCancelZone = inside;
    }

    isPointInTrayCancelZone(clientX, clientY) {
        const zone = this.template.querySelector('[data-cancel-zone="true"]');
        if (!zone) {
            return false;
        }

        const rect = zone.getBoundingClientRect();
        return (
            clientX >= rect.left &&
            clientX <= rect.right &&
            clientY >= rect.top &&
            clientY <= rect.bottom
        );
    }

    get managerResetDisabled() {
        return !this.isViewingAsOther;
    }

    get rescheduleSubmitDisabled() {
        return this.rescheduleLoading || !this.rescheduleSelection;
    }

    get absenceDebugSummary() {
        const absCount = this.absences ? this.absences.length : 0;
        const ids =
            this.debugInfo && Array.isArray(this.debugInfo.absenceResourceIds)
                ? this.debugInfo.absenceResourceIds
                : [];
        const resourceLabel = ids.length ? ids.join(', ') : 'none';
        return `Absence fetch: ${absCount} record(s); resources: ${resourceLabel}`;
    }

    get absenceDebugRows() {
        const absences = this.absences || [];
        return absences.map(abs => {
            const startLocal = abs.start
                ? this.convertUtcToUserLocal(abs.start)
                : null;
            const endLocal = abs.endTime
                ? this.convertUtcToUserLocal(abs.endTime)
                : null;
            const rangeLabel =
                startLocal && endLocal
                    ? this.formatTimeRange(startLocal, endLocal)
                    : 'No time available';

            return {
                key: abs.absenceId || abs.subject || rangeLabel,
                subject: abs.subject || 'Absence',
                resourceId: abs.resourceId,
                range: rangeLabel
            };
        });
    }

    get hasAbsenceDebugRows() {
        return this.absenceDebugRows.length > 0;
    }

    // Position + size of the floating event
    get dragGhostStyle() {
        const position = this.dragGhostAnchoredToCalendar ? 'absolute' : 'fixed';
        return `position:${position};top:${this.dragGhostY}px;left:${this.dragGhostX}px;width:${this.dragGhostWidth}px;height:${this.dragGhostHeight}px;transform:translateX(-50%);`;
    }

    get dragGhostWrapperClass() {
        const classes = ['sfs-drag-ghost'];

        if (
            this.showDragConfirmActions ||
            (this.pendingSchedulePlacement && this.dragGhostVisible)
        ) {
            classes.push('sfs-drag-ghost_interactive');
        }

        if (this.dragGhostAnchoredToCalendar) {
            classes.push('sfs-drag-ghost_anchored');
        }

        return classes.join(' ');
    }


    // Classes for the inner event block
    get dragGhostClass() {
        const base = 'sfs-calendar-event sfs-calendar-event_ghost';
        return this.dragGhostTypeClass
            ? `${base} ${this.dragGhostTypeClass}`
            : base;
    }

    get dragHelperText() {
        if (this.showDragConfirmActions) {
            return 'Tap ✓ to schedule or ✕ to cancel';
        }

        return '';
    }

    get showDragConfirmActions() {
        return (
            (this.dragRequiresExplicitConfirmation && this.dragGhostVisible) ||
            (this.isAwaitingScheduleConfirmation && !!this.pendingSchedulePlacement)
        );
    }


    get isCrewCountUrgent() {
        if (!this.appointments || !this.appointments.length) {
            return false;
        }

        const now = new Date();
        const in48 = new Date(now.getTime() + 48 * 60 * 60 * 1000);

        return this.appointments.some(a => {
            if (!a.isCrewAssignment || a.isMyAssignment || !a.schedStart) {
                return false;
            }
            const start = new Date(a.schedStart);
            return start >= now && start <= in48;
        });
    }

    _itemCount(mode) { return this.getFilteredListModeItems(mode).length; }

    _markWorkOrderStatus(workOrderId, apexFn, {
        successTitle = 'Status updated',
        successBody = '',
        errorTitle = 'Error updating status',
        debugNote = ''
    } = {}) {
        if (!workOrderId) { return; }
        this.checkOnline();
        if (this.isOffline) {
            this.showToast('Offline', 'You must be online to update the work order status.', 'warning');
            return;
        }
        this.isLoading = true;
        apexFn({ workOrderId })
            .then(() => {
                this.showToast(successTitle, successBody, 'success');
                return this.loadAppointments({ preserveScroll: true });
            })
            .catch(error => {
                const message = this.reduceError(error);
                if (debugNote) { this.debugInfo = { note: debugNote, errorMessage: message }; }
                this.showToast(errorTitle, message, 'error');
            })
            .finally(() => { this.isLoading = false; });
    }

    get myCount() { return this._itemCount('my'); }

    get crewCount() { return this._itemCount('crew'); }

    get transferRequestCount() {
        return (this.transferRequests && Array.isArray(this.transferRequests))
            ? this.transferRequests.length
            : 0;
    }

    get submittedTransferRequestCount() {
        return this.submittedTransferRequests.length;
    }

    get sortedTransferRequests() {
        return this.sortListItems(this.transferRequests || []);
    }

    get sortedSubmittedTransferRequests() {
        return this.sortListItems(this.submittedTransferRequests || []);
    }

    get partsReadyCount() { return this._itemCount('partsReady'); }

    get fulfillingCount() { return this._itemCount('fulfilling'); }

    get partsProbeShippedCount() { return this._itemCount('partsProbeShipped'); }

    get ownedAppointments() {
        if (!this.appointments) return [];

        const anyFlagged = this.appointments.some(
            a => a.isMyAssignment || a.isCrewAssignment
        );

        if (anyFlagged) {
            const myAssignments = this.appointments.filter(
                a => a.isMyAssignment
            );
            if (myAssignments.length > 0) {
                return myAssignments;
            }
        }

        return this.appointments;
    }

    get hasRecentWorkOrders() {
        return this.activeRecentWorkOrderCards.length > 0;
    }

    get createdRecentCount() {
        return this.createdRecentWorkOrderCards.length;
    }

    get modifiedRecentCount() {
        return this.modifiedRecentWorkOrderCards.length;
    }

    get recentModeTabs() {
        const tabs = [
            { value: 'created', label: 'Created', count: this.createdRecentCount },
            { value: 'modified', label: 'Modified', count: this.modifiedRecentCount }
        ];

        return tabs.map(tab => ({
            ...tab,
            isActive: this.recentMode === tab.value,
            className: this.getRecentModeTabClass(tab.value),
            countLabel: `(${tab.count})`
        }));
    }

    get activeRecentWorkOrderCards() {
        return this.recentMode === 'modified'
            ? this.modifiedRecentWorkOrderCards
            : this.createdRecentWorkOrderCards;
    }

    get isCreatedRecentMode() {
        return this.recentMode === 'created';
    }

    get hasHistoryItems() {
        return this.historyGroups.length > 0;
    }

    get isRmaSearchDisabled() {
        return !this.rmaLoaded || this.isRmaLoading || this.isOffline;
    }

    get rmaFiltersApplied() {
        return Boolean((this.rmaSearchFilter || '').trim()) || this.rmaExcludeTracked;
    }

    get rmaEmptyMessage() {
        return this.rmaFiltersApplied
            ? 'No RMAs match the current filters.'
            : 'No open RMAs found.';
    }

    get filteredRmaItems() {
        const filter = (this.rmaSearchFilter || '').trim().toLowerCase();
        const norm = v => (v == null ? '' : String(v).trim().toLowerCase());
        return this.rmaItemsWithMeta.filter(r => {
            if (this.rmaExcludeTracked && (r.rmaTracking || r.engineerRmaTracking)) {
                return false;
            }
            if (!filter) return true;
            return (
                norm(r.rmaName).includes(filter) ||
                norm(r.rmaType).includes(filter) ||
                norm(r.workOrderNumber).includes(filter) ||
                norm(r.opportunityName).includes(filter) ||
                norm(r.accountName).includes(filter) ||
                norm(r.serialNumber).includes(filter) ||
                norm(r.assetProductName).includes(filter) ||
                norm(r.rmaTracking).includes(filter) ||
                norm(r.engineerRmaTracking).includes(filter)
            );
        });
    }

    get hasRmaItems() {
        return this.filteredRmaItems.length > 0;
    }

    get rmaItemsWithMeta() {
        return this.rmaItems.map(r => {
            const hasRmaTracking = Boolean(r.rmaTracking);
            const hasEngineerTracking = Boolean(r.engineerRmaTracking);
            const isEditing = this.rmaTrackingEditMode[r.rmaId] === true;
            const createdLabel = r.createdDate
                ? new Date(r.createdDate).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })
                : null;
            return {
                ...r,
                isLoanerReturn: (r.rmaType || '').toLowerCase().includes('loaner return'),
                showEngineerTrackingBlock: !hasRmaTracking,
                isEditingEngineerTracking: !hasEngineerTracking || isEditing,
                engineerTrackingDraft: this.rmaTrackingDraft[r.rmaId] !== undefined
                    ? this.rmaTrackingDraft[r.rmaId]
                    : (r.engineerRmaTracking || ''),
                isEngineerTrackingSaving: Boolean(this.rmaTrackingSaving[r.rmaId]),
                createdLabel
            };
        });
    }

    get isHistoryLoadDisabled() {
        return this.isHistoryLoading || this.isOffline;
    }

    get isHistorySearchDisabled() {
        return !this.historyLoaded || this.isHistoryLoading || this.isOffline;
    }

    get historyModeTabs() {
        const tabs = [
            {
                value: 'nonPreventative',
                label: 'Other',
                count: this.nonPreventativeHistoryCards.length
            },
            {
                value: 'preventative',
                label: 'PMs',
                count: this.preventativeMaintenanceHistoryCards.length
            }
        ];

        return tabs.map(tab => ({
            ...tab,
            isActive: this.historyMode === tab.value,
            className: this.getHistoryModeTabClass(tab.value),
            countLabel: `(${tab.count})`
        }));
    }

    get activeHistoryCards() {
        return this.historyMode === 'preventative'
            ? this.preventativeMaintenanceHistoryCards
            : this.nonPreventativeHistoryCards;
    }

    get historyEmptyMessage() {
        if (!this.historyLoaded) {
            return 'Click Load history to view completed work orders.';
        }
        if (this.historyFiltersApplied) {
            return 'No history items match those filters.';
        }
        return this.historyMode === 'preventative'
            ? 'No historical PM work orders were found.'
            : 'No historical non-PM work orders were found.';
    }

    get createdRecentWorkOrderCards() {
        const source = [
            ...this.ownedAppointmentsWithCards,
            ...this.unscheduledListItems
        ];
        const recent = source.filter(item => this.isRecentlyCreatedWorkOrder(item));
        const sorted = recent.sort((a, b) => {
            const aTime = this.getCreatedTimeValue(a);
            const bTime = this.getCreatedTimeValue(b);
            return bTime - aTime;
        });

        const filteredList = this.filterByWorkOrderNumber(sorted);
        return this.buildListAppointments(filteredList);
    }

    get modifiedRecentWorkOrderCards() {
        const source = [
            ...this.ownedAppointmentsWithCards,
            ...this.unscheduledListItems
        ];
        const recent = source.filter(item => this.isRecentlyModifiedByCurrentUser(item));
        const sorted = recent.sort((a, b) => {
            const aTime = this.getLastModifiedTimeValue(a);
            const bTime = this.getLastModifiedTimeValue(b);
            return bTime - aTime;
        });

        const filteredList = this.filterByWorkOrderNumber(sorted);
        return this.buildListAppointments(filteredList);
    }

    get recentWorkOrderGroups() {
        return this.buildAppointmentGroups(this.activeRecentWorkOrderCards || []);
    }

    get historyCards() {
        const items = this.historyItems || [];
        const mapped = items.map((item, index) => this.buildHistoryCard(item, index));
        const filtered = this.filterHistoryCards(mapped);

        return filtered.sort((a, b) => {
            const aTime = this.getHistorySortValue(a);
            const bTime = this.getHistorySortValue(b);
            return bTime - aTime;
        });
    }

    get preventativeMaintenanceHistoryCards() {
        return (this.historyCards || []).filter(card =>
            this.isPreventativeMaintenanceWorkType(card)
        );
    }

    get nonPreventativeHistoryCards() {
        return (this.historyCards || []).filter(
            card => !this.isPreventativeMaintenanceWorkType(card)
        );
    }

    get historyGroups() {
        return this.buildHistoryGroups(this.activeHistoryCards || []);
    }

    get historyFiltersApplied() {
        return Boolean((this.historySearchFilter || '').trim());
    }

    get ownedAppointmentsWithCards() {
        return this.ownedAppointments.map(appt => ({
            ...appt,
            cardId: appt.appointmentId,
            hasAppointment: true
        }));
    }

    // For PM context, include all SA records regardless of direct vs crew assignment.
    // ownedAppointments drops crew-only SAs when any direct assignment exists, which
    // causes crew-assigned PM WOs to disappear from the Scheduled pill after the PM
    // scope loads (they're also excluded from unscheduledWorkOrders via
    // workOrdersWithThisTech, leaving them invisible).
    get pmAppointmentsWithCards() {
        return (this.appointments || []).map(appt => ({
            ...appt,
            cardId: appt.appointmentId,
            hasAppointment: true
        }));
    }

    get quotesCount() { return this._itemCount('quotes'); }

    get revisitPendingAppointments() {
        return this.ownedAppointmentsWithCards.filter(
            appt => appt.latestReturnVisitRequired
        );
    }

    get revisitPendingCount() { return this._itemCount('revisitPending'); }
    get newCount() { return this._itemCount('new'); }
    get needQuoteCount() { return this._itemCount('needQuote'); }
    get poRequestedCount() { return this._itemCount('poRequested'); }
    get quoteSentCount() { return this._itemCount('quoteSent'); }
    get waitingForPoCount() { return this._itemCount('waitingForPo'); }
    get generateFsrCount() { return this._itemCount('generateFsr'); }
    get reGenerateFsrCount() { return this._itemCount('reGenerateFsr'); }
    get readyForCloseCount() { return this._itemCount('readyForClose'); }
    get readyToShipCount() { return this._itemCount('readyToShip'); }
    get confirmShippingCount() { return this._itemCount('confirmShipping'); }
    get pendingShipmentCount() { return this._itemCount('pendingShipment'); }
    get quoteAttachedCount() { return this._itemCount('quoteAttached'); }
    get updateNeededCount() { return this._itemCount('updateNeeded'); }
    get probeProposalPriceQuoteCount() { return this._itemCount('probeProposalPriceQuote'); }
    get pendingReceiptProbeCount() { return this._itemCount('pendingReceiptProbe'); }
    get probeRepairEvaluationCount() { return this._itemCount('probeRepairEvaluation'); }
    get probeEvaluationCompleteCount() { return this._itemCount('probeEvaluationComplete'); }
    get probePendingApprovalCount() { return this._itemCount('probePendingApproval'); }
    get probeRepairApprovedCount() { return this._itemCount('probeRepairApproved'); }
    get probeExchangeApprovedCount() { return this._itemCount('probeExchangeApproved'); }
    get probeRepairDeclinedCount() { return this._itemCount('probeRepairDeclined'); }

    get visibleAppointments() {
        if (!this.appointments) return [];

        const filteredList = this.getFilteredListModeItems(this.listMode);
        const tabFilteredList = this.filterListModeItemsByPrimaryTab(
            filteredList,
            this.listModePrimaryTab
        );
        const sortedList = this.sortListItems(tabFilteredList);
        return this.buildListAppointments(sortedList);
    }

    filterListModeItemsByPrimaryTab(items, tabValue) {
        if (!Array.isArray(items)) {
            return [];
        }

        if (tabValue !== 'scheduled' && tabValue !== 'unscheduled') {
            return items;
        }

        const shouldShowScheduled = tabValue === 'scheduled';
        return items.filter(item =>
            shouldShowScheduled
                ? this.isScheduledListModeItem(item)
                : !this.isScheduledListModeItem(item)
        );
    }

    isScheduledListModeItem(item) {
        if (!item) {
            return false;
        }

        const totalVisits = item.serviceAppointmentCount || 0;
        if (totalVisits <= 0) {
            return Boolean(item.appointmentId);
        }

        const selectedVisitNumber = this.getSelectedVisitNumber(item);
        return this.isVisitScheduled(item, selectedVisitNumber);
    }

    getSelectedVisitNumber(item) {
        const totalVisits = item?.serviceAppointmentCount || 0;
        if (totalVisits <= 0) {
            return 0;
        }

        const workOrderId = item?.workOrderId;
        const persistedValue = workOrderId
            ? this.selectedVisitByWorkOrder[workOrderId]
            : null;
        const parsedPersisted = Number.parseInt(persistedValue, 10);

        if (
            Number.isInteger(parsedPersisted) &&
            parsedPersisted >= 1 &&
            parsedPersisted <= totalVisits
        ) {
            return parsedPersisted;
        }

        return totalVisits;
    }

    getScheduledVisitCount(item) {
        const totalVisits = item?.serviceAppointmentCount || 0;
        if (totalVisits <= 0) {
            return 0;
        }

        const unscheduledVisitCount =
            this.getUnscheduledServiceAppointmentCount(item);
        const scheduledVisitCount = totalVisits - unscheduledVisitCount;

        return Math.max(0, scheduledVisitCount);
    }

    getUnscheduledServiceAppointmentCount(item) {
        const explicitCount = item?.unscheduledServiceAppointmentCount;
        if (Number.isInteger(explicitCount) && explicitCount >= 0) {
            return explicitCount;
        }

        const workOrderId = item?.workOrderId;
        if (!workOrderId || !Array.isArray(this.unscheduledWorkOrders)) {
            return 0;
        }

        const unscheduledMatch = this.unscheduledWorkOrders.find(
            wo => wo.workOrderId === workOrderId
        );

        if (!unscheduledMatch) {
            return 0;
        }

        const fallbackCount = unscheduledMatch.unscheduledServiceAppointmentCount;
        return Number.isInteger(fallbackCount) && fallbackCount >= 0
            ? fallbackCount
            : 0;
    }

    buildVisitOptions(totalVisits, visitScheduleDates) {
        const dates = Array.isArray(visitScheduleDates) ? visitScheduleDates : [];

        return Array.from({ length: totalVisits }, (_, index) => {
            const number = index + 1;
            const dateLabel = this.formatVisitDateLabel(dates[index]);

            return {
                label: dateLabel ? `Visit ${number} • ${dateLabel}` : `Visit ${number}`,
                value: String(number),
                dateLabel
            };
        });
    }

    isVisitScheduled(item, visitNumber) {
        if (!item || !Number.isInteger(visitNumber) || visitNumber <= 0) {
            return false;
        }

        const visitScheduleDates = Array.isArray(item.visitScheduleDates)
            ? item.visitScheduleDates
            : [];
        const visitScheduleDate = visitScheduleDates[visitNumber - 1];

        if (visitScheduleDate) {
            return true;
        }

        const totalVisits = item.serviceAppointmentCount || 0;
        const scheduledVisitCount = this.getScheduledVisitCount(item);
        return (
            totalVisits > 0 &&
            Number.isInteger(scheduledVisitCount) &&
            visitNumber <= scheduledVisitCount
        );
    }

    formatVisitDateLabel(dateValue) {
        if (!dateValue) {
            return null;
        }

        const localDate = this.convertUtcToUserLocal(dateValue);
        if (!(localDate instanceof Date) || Number.isNaN(localDate.getTime())) {
            return null;
        }

        return new Intl.DateTimeFormat('en-US', {
            month: 'short',
            day: 'numeric',
            year: 'numeric'
        }).format(localDate);
    }

    getListModeBaseList(listMode) {
        const ownedAppointments = this.ownedAppointmentsWithCards;
        const quoteWorkOrders = this.quoteWorkOrders;
        const unscheduledWorkOrders = this.unscheduledListItems;

        // Probe-specific cases with unique logic
        switch (listMode) {
            case 'probeProposalPriceQuote':
                return this.getProbeRepairStageItems('Proposal/Price Quote');

            case 'probeRepairEvaluation':
                return this.getProbeRepairStageItems('Repair Evaluation').filter(
                    item => !this.isPendingReceiptOfProbeItem(item)
                );

            case 'pendingReceiptProbe':
                return this.getPendingReceiptOfProbeItems();

            case 'probeEvaluationComplete':
                return this.getProbeRepairStageItems('Evaluation Complete');

            case 'probePendingApproval': {
                const pendingItems = [
                    ...this.ownedAppointmentsWithCards,
                    ...this.unscheduledListItems
                ];
                return pendingItems.filter(item =>
                    this.isPendingApprovalStatus(item) && !this.isRepairDecisionStatus(item)
                );
            }

            case 'probeRepairApproved':
                return this.getProbeRepairDecisionItems('Repair Approved');

            case 'probeExchangeApproved':
                return this.getProbeRepairDecisionItems('Exchange Approved');

            case 'probeRepairDeclined':
                return this.getProbeRepairDecisionItems('Repair Declined');

            case 'crew':
                return ownedAppointments.filter(a => a.isCrewAssignment);

            case 'partsReady':
                return ownedAppointments.filter(
                    a =>
                        a.allPartsEnRoute &&
                        !this.isGenerateFsrStatus(a) &&
                        !this.isReGenerateFsrStatus(a)
                );

            case 'fulfilling':
                return ownedAppointments.filter(
                    a => a.somePartsEnRoute && !a.allPartsEnRoute
                );

            case 'quotes':
                return ownedAppointments
                    .filter(appt =>
                        this.isQuoteStatus(this.resolveQuoteStatus(appt))
                    )
                    .concat(quoteWorkOrders);

            case 'unscheduled':
                if (this.listModePrimaryTab === 'all') {
                    return ownedAppointments.concat(unscheduledWorkOrders);
                }

                return unscheduledWorkOrders;

            case 'revisitPending':
                return this.revisitPendingAppointments;

            case 'my':
                if (this.listModePrimaryTab === 'all') {
                    return ownedAppointments.concat(unscheduledWorkOrders);
                }

            default: {
                // Data-driven: cases that filter both ownedAppointments and a second list
                const unscheduledFilterFns = {
                    new:               a => this.isNewStatus(a),
                    partsProbeShipped: a => this.isPartsProbeShippedStatus(a),
                    waitingForPo:      a => this.isWaitingForPoItem(a),
                    generateFsr:       a => this.isGenerateFsrStatus(a),
                    reGenerateFsr:     a => this.isReGenerateFsrStatus(a),
                    readyForClose:     a => this.isReadyForCloseStatus(a),
                    readyToShip:       a => this.isReadyToShipStatus(a),
                    confirmShipping:   a => this.isConfirmShippingStatus(a),
                    updateNeeded:      a => this.isUpdateNeededStatus(a)
                };
                const quoteFilterFns = {
                    needQuote:       a => this.resolveQuoteStatus(a) === 'Action Needed',
                    poRequested:     a => this.resolveQuoteStatus(a) === 'PO Requested',
                    quoteSent:       a => this.resolveQuoteStatus(a) === 'Quote Sent',
                    pendingShipment: a => this.resolveQuoteStatus(a) === 'Pending Shipment',
                    quoteAttached:   a => this.isQuoteAttachedAppointment(a)
                };
                if (unscheduledFilterFns[listMode]) {
                    const fn = unscheduledFilterFns[listMode];
                    return ownedAppointments.filter(fn).concat(unscheduledWorkOrders.filter(fn));
                }
                if (quoteFilterFns[listMode]) {
                    const fn = quoteFilterFns[listMode];
                    return ownedAppointments.filter(fn).concat(quoteWorkOrders.filter(fn));
                }
                return ownedAppointments;
            }
        }
    }

    getProbeRepairStageItems(stageLabel) {
        const normalizedStage = this.normalizeStatusLabel(stageLabel);
        const items = [
            ...this.ownedAppointmentsWithCards,
            ...this.unscheduledListItems
        ];

        return items.filter(
            item =>
                this.normalizeStatusLabel(item?.opportunityStage) ===
                normalizedStage && !this.isRepairDecisionStatus(item)
        );
    }

    getPendingReceiptOfProbeItems() {
        const items = [
            ...this.ownedAppointmentsWithCards,
            ...this.unscheduledListItems
        ];

        return items.filter(item => this.isPendingReceiptOfProbeItem(item));
    }

    getProbeRepairDecisionItems(statusLabel) {
        const normalizedStatus = this.normalizeStatusLabel(statusLabel);
        const items = [
            ...this.ownedAppointmentsWithCards,
            ...this.unscheduledListItems
        ];

        return items.filter(
            item => {
                if (!this.isProbeRepairRecord(item)) {
                    return false;
                }

                const itemStatus = this.normalizeStatusLabel(
                    item?.workOrderStatus || item?.status
                );
                if (itemStatus !== normalizedStatus) {
                    return false;
                }

                if (normalizedStatus === 'repair declined') {
                    return this.isRepairDeclinedStage(item);
                }

                return true;
            }
        );
    }

    getFilteredListModeItems(listMode, opportunityType = this.listOpportunityType) {
        const baseList = this.getListModeBaseList(listMode);
        const waitingFilteredList =
            listMode === 'waitingForPo' ||
            listMode === 'unscheduled' ||
            listMode === 'my'
                ? baseList
                : baseList.filter(item => !this.isWaitingForPoItem(item));
        const opportunityFilteredList = this.filterByOpportunityTypeValue(
            waitingFilteredList,
            opportunityType
        );
        const nonPreventativeList = this.filterOutPreventativeMaintenance(
            opportunityFilteredList
        );
        const nonTerminalList =
            this.filterOutTerminalWorkOrders(nonPreventativeList);
        return this.filterByWorkOrderNumber(nonTerminalList);
    }

    get preventativeMaintenanceAppointments() {
        const ownedAppointments = this.pmAppointmentsWithCards;
        const unscheduledWorkOrders = this.unscheduledListItems;
        const preventativeMaintenance = [
            ...ownedAppointments,
            ...unscheduledWorkOrders
        ]
            .filter(appt => this.isPreventativeMaintenanceWorkType(appt));

        const list = this.getPreventativeMaintenanceTabItems(
            this.preventativeMaintenanceActiveTab,
            preventativeMaintenance
        );
        const filteredList = this.filterByWorkOrderNumber(list);
        const sortedList = this.sortPreventativeMaintenanceItems(filteredList);
        return this.buildListAppointments(sortedList);
    }

    get hasPreventativeMaintenanceAppointments() {
        return (this.preventativeMaintenanceAppointments || []).length > 0;
    }

    get appointmentGroups() {
        return this.buildAppointmentGroups(this.visibleAppointments || [], {
            groupSortMode: 'listSort'
        });
    }

    get paginatedVisibleAppointments() {
        return (this.visibleAppointments || []).slice(0, this.listVisibleCount);
    }

    get paginatedAppointmentGroups() {
        return this.buildAppointmentGroups(this.paginatedVisibleAppointments, {
            groupSortMode: 'listSort'
        });
    }

    get hasMoreListItems() {
        return (this.visibleAppointments || []).length > this.listVisibleCount;
    }

    get preventativeMaintenanceGroups() {
        const groupSortMode = this.preventativeMaintenanceSortValue === 'nextServiceDateAsc'
            ? 'date'
            : 'listSort';
        return this.buildAppointmentGroups(
            this.preventativeMaintenanceAppointments || [],
            {
                groupSortMode
            }
        );
    }

    get preventativeMaintenanceCounts() {
        const ownedAppointments = this.pmAppointmentsWithCards;
        const unscheduledWorkOrders = this.unscheduledListItems;
        const preventativeMaintenance = [
            ...ownedAppointments,
            ...unscheduledWorkOrders
        ]
            .filter(appt => this.isPreventativeMaintenanceWorkType(appt));

        const unscheduledNext30 = this.getPreventativeMaintenanceTabItems(
            'unscheduledNext30',
            preventativeMaintenance
        ).length;
        const unscheduledAfter30 = this.getPreventativeMaintenanceTabItems(
            'unscheduledAfter30',
            preventativeMaintenance
        ).length;
        const scheduled = this.getPreventativeMaintenanceTabItems(
            'scheduled',
            preventativeMaintenance
        ).length;
        const readyForClose = this.getPreventativeMaintenanceTabItems(
            'readyForClose',
            preventativeMaintenance
        ).length;
        const completed = this.getPreventativeMaintenanceTabItems(
            'completed',
            preventativeMaintenance
        ).length;

        return {
            unscheduledNext30,
            unscheduledAfter30,
            scheduled,
            readyForClose,
            completed
        };
    }

    get preventativeMaintenanceUnscheduledNextThirtyDaysCount() {
        return this.preventativeMaintenanceCounts.unscheduledNext30 || 0;
    }

    get preventativeMaintenanceUnscheduledNextThirtyDaysLabel() {
        const count = this.preventativeMaintenanceUnscheduledNextThirtyDaysCount;
        if (count === 1) {
            return '1 unscheduled PM within the next 30 days';
        }

        return `${count} unscheduled PMs within the next 30 days`;
    }

    get preventativeMaintenanceEmptyMessage() {
        const activeTab = this.preventativeMaintenanceActiveTab;

        switch (activeTab) {
            case 'scheduled':
                return 'No scheduled preventative maintenance work orders were found.';
            case 'readyForClose':
                return 'No ready for close preventative maintenance work orders were found.';
            case 'completed':
                return 'No completed preventative maintenance work orders were found in the past 2 weeks.';
            case 'unscheduledAfter30':
                return 'No unscheduled preventative maintenance work orders were found after the next 30 days.';
            case 'unscheduledNext30':
            default:
                return 'No unscheduled preventative maintenance work orders were found within the next 30 days.';
        }
    }

    buildListAppointments(baseList) {
        return baseList.map(item => {
            const isQuickScheduleExpanded = Boolean(
                this.quickScheduleExpanded[item.cardId]
            );
            const completedVisitCount = item.completedVisitCount ?? 0;
            const serviceAppointmentCount = item.serviceAppointmentCount ?? 0;
            const visitNumber = this.getSelectedVisitNumber(item);
            const visitLabel = visitNumber > 0 ? `Visit ${visitNumber}` : null;
            const visitOptions = this.buildVisitOptions(
                serviceAppointmentCount,
                item.visitScheduleDates
            );
            const selectedVisitDateLabel =
                visitOptions.find(option => option.value === String(visitNumber))
                    ?.dateLabel || null;
            const quoteLineItems = this.normalizeQuoteLineItems(
                item.quoteLineItems
            );
            const quoteLineItemsExpanded = Boolean(
                this.quoteLineItemsExpanded[item.cardId]
            );
            const hasLineItemTracking = quoteLineItems.some(
                line => line.trackingNumber
            );
            const resolvedTrackingNumber = this.resolveTrackingNumber(
                item,
                hasLineItemTracking
            );
            const loanerTrackingNumber = item.loanerTrackingNumber || null;
            const showQuoteLineItems = quoteLineItems.length > 0;
            const groupedQuoteLineItems = this.groupQuoteLineItems(
                quoteLineItems
            );
            const quoteLineItemsToggleLabel = 'Parts/Probes';
            const quoteLineItemsExpandedIcon = quoteLineItemsExpanded
                ? 'utility:chevrondown'
                : 'utility:chevronright';
            const quickScheduleStart = this.getQuickScheduleValue(item);
            const quickScheduleLabel = this.getQuickScheduleToggleLabel(
                item,
                isQuickScheduleExpanded
            );
            const scheduleOnCalendarLabel = this.getScheduleOnCalendarLabel(item);

            const showScheduleActions = this.shouldShowScheduleActions(item);
            const journey = this.buildWorkOrderJourney(item);
            const journeyExpanded = Boolean(this.journeyExpanded[item.cardId]);
            const journeyToggleLabel = journeyExpanded ? 'Hide checklist' : 'View checklist';
            const journeyToggleTitle = journeyExpanded
                ? 'Hide full checklist'
                : 'View full checklist';
            const journeyToggleIcon = journeyExpanded
                ? 'utility:chevrondown'
                : 'utility:chevronright';
            const quickScheduleBodyId = `qs-${item.cardId}`;
            const hasScheduleAddress = this.hasScheduleAddress(item);
            const scheduleDisabled = !hasScheduleAddress;
            const scheduleBlockedReason = this.getAddressBlockedReason(item);
            const showAddressHelpBubble = this.addressHelpCardId === item.cardId;
            const showShippingAddressSection = true;
            const showShippingAddress =
                showShippingAddressSection && item.hasShippingAddress;
            const markReadyToShipDisabled =
                item.showMarkPoAttachedAction &&
                !this.hasCompleteShippingAddress(item);
            const markReadyToShipButtonClass = [
                'sfs-quote-action-button',
                markReadyToShipDisabled ? 'sfs-quote-action-button_disabled' : ''
            ]
                .filter(Boolean)
                .join(' ');
            const confirmShippingDisabled =
                item.showConfirmShippingAction &&
                !this.hasCompleteShippingAddress(item);
            const confirmShippingButtonClass = [
                'sfs-repair-approval-button',
                confirmShippingDisabled ? 'sfs-repair-approval-button_disabled' : ''
            ]
                .filter(Boolean)
                .join(' ');
            const scheduleActionsClass = [
                'sfs-actions',
                'sfs-schedule-actions',
                'sfs-quick-schedule__actions-inline',
                'sfs-option-actions',
                scheduleDisabled ? 'sfs-schedule-actions_disabled' : ''
            ]
                .filter(Boolean)
                .join(' ');
            const quickScheduleButtonClass = [
                'sfs-compact-button',
                'sfs-option-button',
                scheduleDisabled ? 'sfs-option-button_disabled' : ''
            ]
                .filter(Boolean)
                .join(' ');
            const calendarButtonClass = [
                'sfs-compact-button',
                'sfs-option-button',
                'sfs-option-button_primary',
                scheduleDisabled ? 'sfs-option-button_disabled' : ''
            ]
                .filter(Boolean)
                .join(' ');

            const workOrderStatusPill = this.getWorkOrderStatusPill(item);
            const isContractPm = this.isPreventativeMaintenanceWorkType(item) &&
                String(item.billingType || '').toLowerCase() === 'contract';
            const workOrderDescription = item.workOrderDescription || item.description || null;

            return {
                ...item,
                isContractPm,
                workOrderDescription,
                quoteLineItems,
                showQuoteLineItems,
                quoteLineItemsExpanded,
                quoteLineItemsToggleLabel,
                quoteLineItemsExpandedIcon,
                completedVisitCount,
                serviceAppointmentCount,
                visitNumber,
                visitLabel,
                visitOptions,
                selectedVisitValue: visitNumber > 0 ? String(visitNumber) : null,
                selectedVisitDateLabel,
                showVisitPill: serviceAppointmentCount > 0,
                showWorkTypePill: this.shouldShowWorkTypePill(item),
                showWorkOrderStatusPill: Boolean(workOrderStatusPill),
                workOrderStatusPillLabel: workOrderStatusPill?.label,
                workOrderStatusPillClass: workOrderStatusPill?.className,
                showScheduleOnCalendar: showScheduleActions,
                showQuickSchedule: showScheduleActions,
                quickScheduleStart,
                quickScheduleExpanded: isQuickScheduleExpanded,
                quickScheduleLabel,
                scheduleOnCalendarLabel,
                quickScheduleDateLabel: this.getQuickScheduleDateLabel(item),
                quickScheduleActionLabel: this.getQuickScheduleActionLabel(item),
                cardClass: 'sfs-card',
                hasLineItemTracking,
                resolvedTrackingNumber,
                showResolvedTracking: Boolean(resolvedTrackingNumber),
                loanerTrackingNumber,
                showLoanerTracking: Boolean(loanerTrackingNumber),
                groupedQuoteLineItems,
                journey,
                journeyExpanded,
                journeyToggleLabel,
                journeyToggleTitle,
                journeyToggleIcon,
                quickScheduleBodyId,
                hasCompleteAddress: this.hasCompleteAddress(item),
                hasScheduleAddress,
                scheduleDisabled,
                scheduleBlockedReason,
                scheduleActionsClass,
                quickScheduleButtonClass,
                calendarButtonClass,
                showAddressHelpBubble,
                showShippingAddress,
                showShippingAddressSection,
                markReadyToShipDisabled,
                markReadyToShipButtonClass,
                confirmShippingDisabled,
                confirmShippingButtonClass
            };
        });
    }

    buildAppointmentGroups(appointments, options = {}) {
        const groupSortMode = options.groupSortMode || 'date';
        const groups = new Map();

        appointments.forEach((appt, index) => {
            const groupInfo = this.getAppointmentGroup(appt);
            const existing = groups.get(groupInfo.key);
            const nextGroup = existing || {
                ...groupInfo,
                appointments: [],
                firstItemIndex: index
            };

            nextGroup.appointments.push(appt);
            groups.set(groupInfo.key, nextGroup);
        });

        return Array.from(groups.values())
            .sort((a, b) => {
                if (groupSortMode === 'listSort') {
                    return a.firstItemIndex - b.firstItemIndex;
                }

                const aValue = Number.isFinite(a.sortValue)
                    ? a.sortValue
                    : Number.POSITIVE_INFINITY;
                const bValue = Number.isFinite(b.sortValue)
                    ? b.sortValue
                    : Number.POSITIVE_INFINITY;

                if (aValue === bValue) {
                    return a.label.localeCompare(b.label);
                }

                return aValue - bValue;
            })
            .map(group => {
                const isCollapsed = Boolean(this.collapsedDayGroups[group.key]);
                const { firstItemIndex, ...groupWithoutMeta } = group;

                return {
                    ...groupWithoutMeta,
                    count: group.appointments.length,
                    isCollapsed,
                    toggleIcon: isCollapsed
                        ? 'utility:chevrondown'
                        : 'utility:chevronup',
                    toggleLabel: isCollapsed ? 'Expand' : 'Collapse'
                };
            });
    }

    get collapseAllDisabled() {
        const groups = this.appointmentGroups || [];
        if (!groups.length) {
            return true;
        }

        return groups.every(group => group.isCollapsed);
    }

    getAppointmentGroup(appt) {
        const startDate = appt.schedStart ? new Date(appt.schedStart) : null;
        const hasValidStart = startDate && !Number.isNaN(startDate.getTime());
        let groupDate = hasValidStart ? startDate : null;

        if (
            !groupDate &&
            this.isPreventativeMaintenanceWorkType(appt) &&
            !appt.hasAppointment
        ) {
            const nextServiceDate = this.parseDateOnlyValue(
                appt?.nextServiceDate
            );
            if (nextServiceDate) {
                groupDate = nextServiceDate;
            }
        }

        if (!groupDate) {
            return {
                key: 'no-date',
                label: 'No scheduled date',
                sortValue: Number.POSITIVE_INFINITY
            };
        }

        const today = new Date();
        const tomorrow = new Date();
        tomorrow.setDate(today.getDate() + 1);

        const groupKey = this.getLocalDateId(groupDate);
        const todayKey = this.getLocalDateId(today);
        const tomorrowKey = this.getLocalDateId(tomorrow);

        let label = groupDate.toLocaleDateString(undefined, {
            weekday: 'long',
            month: 'short',
            day: 'numeric',
            year: 'numeric'
        });

        if (groupKey === todayKey) {
            label = 'Today';
        } else if (groupKey === tomorrowKey) {
            label = 'Tomorrow';
        }

        const sortValue = new Date(
            groupDate.getFullYear(),
            groupDate.getMonth(),
            groupDate.getDate()
        ).getTime();

        return {
            key: groupKey,
            label,
            sortValue
        };
    }

    getLocalDateId(date) {
        return [
            date.getFullYear(),
            String(date.getMonth() + 1).padStart(2, '0'),
            String(date.getDate()).padStart(2, '0')
        ].join('-');
    }

    isQuoteStatus(status) {
        const normalized = this.normalizeStatusLabel(status);
        return this.quoteStatuses.some(
            quoteStatus =>
                this.normalizeStatusLabel(quoteStatus) === normalized
        );
    }

    isWaitingForPoItem(item) {
        return item?.waitingForPoNumber === true;
    }

    isProbeRepairRecord(record) {
        if (!record) {
            return false;
        }

        const recordType =
            record.opportunityRecordType || record.recordTypeName || '';
        return this.normalizeStatusLabel(recordType).includes('probe repair');
    }

    isProbeRepairPendingApproval(record) {
        if (!this.isProbeRepairRecord(record)) {
            return false;
        }

        return (record.opportunityStage || '').trim() === 'Pending Approval';
    }

    isPendingReceiptOfProbeItem(record) {
        const normalizedStage = this.normalizeStatusLabel(record?.opportunityStage);
        const normalizedStatus = this.normalizeStatusLabel(
            record?.workOrderStatus || record?.status
        );
        const isRepairEvaluationStage =
            normalizedStage === 'repair evaluation' ||
            normalizedStage.startsWith('repair evaluation');
        const isInProgressStatus = normalizedStatus.startsWith('in progress');

        if (!isRepairEvaluationStage || !isInProgressStatus) {
            return false;
        }

        return !record?.dateProbeReceivedForRepairEval;
    }

    getWorkOrderStatusPill(record) {
        if (!record) {
            return null;
        }

        if (this.isPendingReceiptOfProbeItem(record)) {
            return {
                label: 'Pending Receipt of Probe',
                className:
                    'sfs-wo-status-pill sfs-wo-status-pill_pending-receipt'
            };
        }

        const normalizedStatus = this.normalizeStatusLabel(
            record?.workOrderStatus || record?.status
        );
        const normalizedOpportunityStage = this.normalizeStatusLabel(
            record?.opportunityStage
        );
        const shouldTreatOpportunityStageAsInProgress =
            !normalizedStatus.startsWith('in progress') &&
            normalizedOpportunityStage === 'in progress';

        if (
            normalizedStatus.startsWith('in progress') ||
            shouldTreatOpportunityStageAsInProgress
        ) {
            return {
                label: 'In Progress',
                className: 'sfs-wo-status-pill sfs-wo-status-pill_in-progress'
            };
        }

        return null;
    }

    isRepairDecisionStatus(record) {
        if (!record) {
            return false;
        }

        const statusLabel = record.workOrderStatus || record.status || '';
        const normalized = this.normalizeStatusLabel(statusLabel);
        if (normalized === 'repair approved') {
            return true;
        }

        if (normalized === 'exchange approved') {
            return true;
        }

        if (normalized === 'repair declined') {
            return this.isRepairDeclinedStage(record);
        }

        return false;
    }

    isRepairDeclinedStage(record) {
        if (!record) {
            return false;
        }

        const statusLabel = record.workOrderStatus || record.status || '';
        const normalizedStatus = this.normalizeStatusLabel(statusLabel);
        if (normalizedStatus !== 'repair declined') {
            return false;
        }

        const stageLabel = record.opportunityStage || '';
        const normalizedStage = this.normalizeStatusLabel(stageLabel);
        return normalizedStage === 'repair declined';
    }

    isPendingApprovalStatus(record) {
        if (!record) {
            return false;
        }

        const statusLabel = record.workOrderStatus || record.status || '';
        const normalizedStatus = this.normalizeStatusLabel(statusLabel);
        if (normalizedStatus === 'pending approval') {
            return true;
        }

        const stageLabel = record.opportunityStage || record.stage || '';
        const normalizedStage = this.normalizeStatusLabel(stageLabel);
        return normalizedStage === 'pending approval';
    }

    shouldShowRepairApprovedAction(record) {
        if (!record?.workOrderId) {
            return false;
        }

        return this.isPendingApprovalStatus(record);
    }

    shouldShowExchangeApprovalAction(record) {
        if (!record?.workOrderId) {
            return false;
        }

        return this.isPendingApprovalStatus(record);
    }

    shouldShowRepairApprovalActions(record) {
        return (
            this.shouldShowRepairApprovedAction(record) ||
            this.shouldShowExchangeApprovalAction(record)
        );
    }

    normalizePoNumberValue(value) {
        if (value === null || value === undefined) {
            return '';
        }
        return String(value).trim();
    }

    getRepairApprovalButtonClass(isDisabled) {
        return `sfs-repair-approval-button${isDisabled ? ' sfs-repair-approval-button_disabled' : ''}`;
    }

    getExchangeApprovalButtonClass(isDisabled) {
        return `sfs-exchange-approval-button${isDisabled ? ' sfs-repair-approval-button_disabled' : ''}`;
    }

    buildPoNumberState(record) {
        const poNumber = this.normalizePoNumberValue(record?.poNumber);
        const hasPoNumber = Boolean(poNumber);
        const shouldShowPoField = Boolean(record?.workOrderId);
        return {
            poNumber,
            isEditingPoNumber: Boolean(record?.isEditingPoNumber),
            poNumberDraft: poNumber,
            hasPoNumber,
            poNumberDisplay: hasPoNumber ? poNumber : 'Add PO number',
            poNumberEditLabel: hasPoNumber ? 'Edit' : 'Add',
            poNumberValueClass: hasPoNumber
                ? 'sfs-po-value'
                : 'sfs-po-value sfs-po-value_empty',
            showPoNumberField: shouldShowPoField,
            repairApprovalDisabled: false,
            repairApprovedButtonClass: this.getRepairApprovalButtonClass(false),
            exchangeApprovedButtonClass: this.getExchangeApprovalButtonClass(false)
        };
    }

    buildServiceSiteState(record) {
        const name = record?.serviceSiteName || '';
        return {
            serviceSiteDisplay: name || 'Add service site',
            serviceSiteValueClass: name
                ? 'sfs-po-value'
                : 'sfs-po-value sfs-po-value_empty'
        };
    }

    shouldShowConfirmShippingAction(record) {
        if (!record?.workOrderId || !this.isProbeSaleRecord(record)) {
            return false;
        }

        const statusLabel = record.workOrderStatus || record.status || '';
        const normalizedStatus = this.normalizeStatusLabel(statusLabel);
        if (normalizedStatus === 'confirm shipping') {
            return true;
        }

        if (normalizedStatus !== 'repair approved') {
            return false;
        }

        const quoteStatus = this.resolveQuoteStatus(record);
        const normalizedQuoteStatus = this.normalizeStatusLabel(quoteStatus);
        return normalizedQuoteStatus === 'ready to ship';
    }

    isConfirmShippingStatus(record) {
        if (!record) {
            return false;
        }

        const statusLabel = record.workOrderStatus || record.status || '';
        return this.normalizeStatusLabel(statusLabel) === 'confirm shipping';
    }

    isReadyToShipStatus(record) {
        if (!record) {
            return false;
        }

        const statusLabel = record.workOrderStatus || record.status || '';
        return this.normalizeStatusLabel(statusLabel) === 'ready to ship';
    }

    getOpportunityStageClass(record) {
        if (!record) {
            return 'sfs-opportunity-meta__value';
        }

        return this.isProbeRepairPendingApproval(record)
            ? 'sfs-opportunity-meta__value sfs-opportunity-meta__value_alert'
            : 'sfs-opportunity-meta__value';
    }

    shouldUseOpportunityStageForProbeRepair(record) {
        if (!record || !this.isProbeRepairRecord(record)) {
            return false;
        }

        const statusLabel = record.workOrderStatus || record.status || '';
        const normalized = this.normalizeStatusLabel(statusLabel);
        if (normalized !== 'in progress' && normalized !== 'action needed') {
            return false;
        }

        return Boolean(record.opportunityStage);
    }

    resolveQuoteStatus(record) {
        if (!record) {
            return '';
        }

        const status = record.workOrderStatus || record.status || '';
        const opportunityStage = record.opportunityStage || '';

        if (this.isProbeRepairRecord(record) && this.isQuoteStatus(opportunityStage)) {
            return opportunityStage;
        }

        return status;
    }

    isPartsProbeShippedStatus(record) {
        if (!record) {
            return false;
        }

        const statusLabel = record.workOrderStatus || record.status || '';
        const normalized = this.normalizeStatusLabel(statusLabel);
        return [
            'parts/probe shipped',
            'parts probe shipped',
            'parts shipped',
            'probe shipped'
        ].includes(normalized);
    }

    hasWorkOrderSubject(record) {
        if (!record) {
            return false;
        }

        const subject =
            (record.workOrderSubject || record.subject || '').trim();
        if (subject.length > 0) {
            return true;
        }

        const fallbackLabel = (
            record.workOrderNumber ||
            record.name ||
            record.workTypeName ||
            ''
        )
            .toString()
            .trim();

        return fallbackLabel.length > 0;
    }

    normalizeAddressValue(value) {
        return (value || '').toString().trim();
    }

    normalizeAccountValue(value) { return this.normalizeAddressValue(value); }

    normalizeReporterContactValue(value) { return this.normalizeAddressValue(value); }

    canAddReporterContact(record) {
        if (!record) {
            return false;
        }

        return (
            !record.contactId &&
            !this.normalizeReporterContactValue(record.reporterContactInfo)
        );
    }

    resolveAccountDisplayName(record) {
        if (!record) {
            return null;
        }

        const accountName = this.normalizeAccountValue(record.accountName);
        const freeText = this.normalizeAccountValue(record.accountNameFreeText);

        if (record.accountId && accountName) {
            return accountName;
        }

        if (!record.accountId && freeText) {
            return freeText;
        }

        return accountName || freeText || null;
    }

    shouldShowAccountEdit(record) {
        if (!record) {
            return false;
        }

        return (
            !record.accountId &&
            !this.normalizeAccountValue(record.accountNameFreeText)
        );
    }

    applyAccountPresentation(record) {
        const accountDisplayName = this.resolveAccountDisplayName(record);
        const probeSaleStatusDescription =
            this.getProbeSaleStatusDescription(record);
        return {
            ...record,
            accountDisplayName,
            hasAccountDisplay: Boolean(accountDisplayName),
            showAccountEdit: this.shouldShowAccountEdit(record),
            probeSaleStatusDescription
        };
    }

    isProbeSaleRecord(record) {
        if (!record) {
            return false;
        }

        const sources = [
            record.opportunityRecordType,
            record.recordTypeName,
            record.workTypeName
        ]
            .filter(Boolean)
            .map(value => this.normalizeStatusLabel(value));

        return sources.some(
            value =>
                value.includes('probe sale') ||
                value.includes('parts sale') ||
                value.includes('probe repair')
        );
    }

    getProbeSaleStatusDescription(record) {
        if (!this.isProbeSaleRecord(record)) {
            return null;
        }

        const statusLabel = record?.workOrderStatus || record?.status || '';
        const normalized = this.normalizeStatusLabel(statusLabel);

        if (normalized.startsWith('quote attached')) {
            return '📄 Quote is attached. Waiting on approval before moving forward.';
        }

        const statusSource = this.shouldUseOpportunityStageForProbeRepair(record)
            ? record.opportunityStage || ''
            : statusLabel;
        const normalizedSource = this.normalizeStatusLabel(statusSource);

        const descriptions = {
            'cancel sale':
                '⛔ Cancel the sale, operations will close this out shortly',

            cancelled:
                '🚫 Job was cancelled. No further action required.',

            'cannot complete':
                '⚠️ Work couldn’t be completed — add notes explaining why.',

            closed:
                '🔒 Fully closed. This job is finished.',

            completed:
                '✅ Work is done. No further action needed.',

            'completed wo':
                '✅ Work is done. No further action needed.',

            'confirmed shipping':
                '✔️ Shipping is confirmed, logistics department is shipping this order out',

            'exchange approved':
                '⇄ Exchange is approved by client, operations working on prepping RMAs',

            'in progress':
                '🔧 You’re actively working this — install, paperwork, or follow-up.',

            'parts probe shipped':
                '📦 Part/probe is on the way. Check tracking and decide next step.',

            'parts requested':
                '🧾 Part/probe has been requested. Waiting for ops to process it.',

            'parts shipped':
                '📦 Part/probe is on the way. Check tracking and decide next step.',

            'parts/probe shipped':
                '📦 Part/probe is on the way. Check tracking and decide next step.',

            'pending shipment':
                '⌯⌲ Operations has sent this to logistics for shipping & entering of a tracking number.',

            'proposal / price quote':
                '🛠️ Operations is putting together a quote for you and will change to Quote Attached once ready',

            'repair evaluation':
                '🔎 Probe is currently getting looked at by our internal team, stand by for an update',

            'evaluation complete':
                '📝 Probe has been evaluated, update coming shortly',

            'pending approval':
                '⌛ Please check with the client if they will approve the repair',

            'probe shipped':
                '📦 Part/probe is on the way. Check tracking and decide next step.',

            'quote attached':
                '🔗 Quote is attached and ready to be sent to the client',

            'quote sent':
                '📬 Quote is with the client, waiting for response',

            'ready for close':
                '📝 Finish notes and complete the closeout.',

            'ready to ship':
                '⏳ Nothing to do. Shipping is preparing the probe.',

            'repair approved':
                 '✔️🔧 Repair is approved and the internal team is actively working on the repair, check back here later for when the repair is complete and ready to ship back out',

            'repair declined':
                '❌ Repair is rejected by the client, wait for operations to change the opportunity stage to "Repair Declined" and then confirm return shipping address',

            'update needed':
                '🔄 Operations is working on your update requested',
        };

        return descriptions[normalizedSource] || null;
    }

    normalizeStateInput(value) {
        const cleaned = this.normalizeAddressValue(value)
            .toUpperCase()
            .replace(/[^A-Z]/g, '');
        return cleaned.slice(0, 2);
    }

    isValidStateAbbreviation(value) {
        return this.normalizeStateInput(value).length === 2;
    }

    composeFullAddress({ street, city, state, postalCode, country }) {
        const parts = [
            this.normalizeAddressValue(street),
            this.normalizeAddressValue(city),
            this.normalizeAddressValue(state),
            this.normalizeAddressValue(postalCode),
            this.normalizeAddressValue(country)
        ].filter(Boolean);

        if (
            parts.length === 1 &&
            parts[0].toLowerCase() === 'united states'
        ) {
            return '';
        }

        return parts.join(', ');
    }

    buildHistoryCard(item, index = 0) {
        const workOrderId = item.workOrderId || item.relatedWorkOrderId;
        const workOrderNumber =
            item.workOrderNumber || item.relatedWorkOrderNumber || '';
        const systemSerialNumber =
            item.systemSerialNumber ||
            item.relatedWorkOrderSystemSerialNumber ||
            '';
        const workOrderSubject =
            item.workOrderSubject || item.relatedWorkOrderSubject || '';
        const workOrderStatus =
            item.workOrderStatus || item.relatedWorkOrderStatus || '';
        const workOrderTrackingNumber = item.workOrderId
            ? item.trackingNumber
            : item.relatedWorkOrderTrackingNumber;
        const hasWorkOrder = Boolean(workOrderId);
        const hasOpportunity = Boolean(item.opportunityId);
        const hasDualHistoryCard = hasOpportunity && hasWorkOrder;
        const isOpportunityOnly = !hasWorkOrder;
        const displayNumber = isOpportunityOnly
            ? item.opportunityNumber
            : workOrderNumber;
        const numberLabel = isOpportunityOnly ? 'Opp #' : 'WO #';
        const subject = isOpportunityOnly
            ? item.opportunityName || displayNumber || ''
            : workOrderSubject || displayNumber || '';
        const statusLabel = isOpportunityOnly
            ? item.opportunityStage
            : workOrderStatus;
        const statusTitle = isOpportunityOnly ? 'Stage' : 'Status';
        const accountName =
            item.accountName ||
            item.accountNameFreeText ||
            '';
        const fullAddress = this.composeFullAddress(item);
        const recordId = isOpportunityOnly
            ? item.opportunityId
            : workOrderId;
        const recordType = isOpportunityOnly ? 'opportunity' : 'workOrder';
        const recordLabel = isOpportunityOnly ? 'Opportunity' : 'Work Order';
        const opportunityCreatedDate = item.opportunityCreatedDate || null;
        const opportunityCreatedLabel = opportunityCreatedDate
            ? this.formatHistoryDate(opportunityCreatedDate)
            : null;
        const opportunityCard = hasOpportunity
            ? {
                recordId: item.opportunityId,
                recordType: 'opportunity',
                recordLabel: 'Opportunity',
                numberLabel: 'Opp #',
                displayNumber: item.opportunityNumber,
                subject: item.opportunityName || item.opportunityNumber || '',
                statusLabel: item.opportunityStage,
                statusTitle: 'Stage',
                accountName,
                fullAddress,
                hasFullAddress: Boolean(fullAddress),
                opportunityCreatedLabel,
                hasOpportunityCreatedDate: Boolean(opportunityCreatedLabel)
            }
            : null;
        const workOrderCard = hasWorkOrder
            ? {
                recordId: workOrderId,
                recordType: 'workOrder',
                recordLabel: 'Work Order',
                numberLabel: 'WO #',
                displayNumber: workOrderNumber,
                subject: workOrderSubject || workOrderNumber || '',
                statusLabel: workOrderStatus,
                statusTitle: 'Status',
                trackingNumber: workOrderTrackingNumber,
                hasTrackingNumber: Boolean(workOrderTrackingNumber)
            }
            : null;

        return {
            ...item,
            cardId: this.buildHistoryCardId(item, recordId, index),
            isOpportunityOnly,
            hasDualHistoryCard,
            opportunityCard,
            workOrderCard,
            displayNumber,
            numberLabel,
            subject,
            statusLabel,
            statusTitle,
            accountName,
            fullAddress,
            hasFullAddress: Boolean(fullAddress),
            recordId,
            recordType,
            recordLabel,
            trackingNumber: isOpportunityOnly
                ? item.trackingNumber
                : workOrderTrackingNumber,
            opportunityCreatedDate,
            opportunityCreatedLabel,
            hasOpportunityCreatedDate: Boolean(opportunityCreatedLabel),
            workOrderNumber,
            systemSerialNumber,
            isCompletedWO: workOrderStatus === 'Completed WO' && Boolean(workOrderId)
        };
    }

    normalizeHistorySearch(value) {
        if (value === null || value === undefined) {
            return '';
        }

        return String(value)
            .trim()
            .toLowerCase();
    }

    buildHistoryCardId(item, recordId, index = 0) {
        const idParts = [
            index,
            item?.opportunityId,
            item?.workOrderId,
            item?.relatedWorkOrderId,
            item?.opportunityNumber,
            item?.workOrderNumber,
            item?.relatedWorkOrderNumber,
            item?.lastModifiedDate,
            item?.opportunityCreatedDate,
            recordId
        ]
            .filter(value => value !== null && value !== undefined && value !== '')
            .map(value => String(value).trim())
            .filter(Boolean);

        if (!idParts.length) {
            return 'history-unknown';
        }

        return `history-${idParts.join('-')}`;
    }

    normalizeLineItemPartSearch(item) {
        const lineItems = Array.isArray(item?.quoteLineItems)
            ? item.quoteLineItems
            : [];

        return lineItems
            .map(lineItem =>
                this.normalizeHistorySearch(
                    lineItem?.productName ||
                        lineItem?.partName ||
                        lineItem?.Part_Name_D__c
                )
            )
            .filter(Boolean)
            .join(' ');
    }

    filterHistoryCards(cards) {
        const searchFilter = this.normalizeHistorySearch(
            this.historySearchFilter
        );

        return (cards || []).filter(card => {
            if (!searchFilter) {
                return true;
            }

            const accountValue = this.normalizeHistorySearch(card.accountName);
            const workOrderValue = this.normalizeHistorySearch(
                card.workOrderNumber
            );
            const opportunityValue = this.normalizeHistorySearch(
                card.opportunityNumber
            );
            const opportunityNameValue = this.normalizeHistorySearch(
                card.opportunityName
            );
            const serialValue = this.normalizeHistorySearch(
                card.systemSerialNumber
            );
            const trackingValue = this.normalizeHistorySearch(
                card.trackingNumber
            );
            const poNumberValue = this.normalizeHistorySearch(card.poNumber);
            const customerIdValue = this.normalizeHistorySearch(
                card.customerId || card.customerID || card.customerNumber
            );
            const lineItemPartNameValue = this.normalizeLineItemPartSearch(card);

            return (
                accountValue.includes(searchFilter) ||
                workOrderValue.includes(searchFilter) ||
                opportunityValue.includes(searchFilter) ||
                opportunityNameValue.includes(searchFilter) ||
                serialValue.includes(searchFilter) ||
                trackingValue.includes(searchFilter) ||
                poNumberValue.includes(searchFilter) ||
                customerIdValue.includes(searchFilter) ||
                lineItemPartNameValue.includes(searchFilter)
            );
        });
    }

    getHistorySortValue(card) {
        return this.toDateValue(
            card?.opportunityCreatedDate || card?.lastModifiedDate
        );
    }

    formatHistoryDate(dateValue) {
        if (!dateValue) {
            return '';
        }

        const localDate = this.convertUtcToUserLocal(dateValue);
        return new Intl.DateTimeFormat('en-US', {
            month: 'short',
            day: '2-digit',
            year: 'numeric'
        }).format(localDate);
    }

    buildHistoryGroups(cards) {
        const groups = new Map();

        (cards || []).forEach(card => {
            const groupInfo = this.getHistoryGroupInfo(card);
            const existing = groups.get(groupInfo.key);
            const nextGroup = existing || {
                ...groupInfo,
                items: []
            };

            nextGroup.items.push(card);
            groups.set(groupInfo.key, nextGroup);
        });

        return Array.from(groups.values())
            .sort((a, b) => {
                const aValue = Number.isFinite(a.sortValue) ? a.sortValue : 0;
                const bValue = Number.isFinite(b.sortValue) ? b.sortValue : 0;
                return bValue - aValue;
            })
            .map(group => ({
                ...group,
                count: group.items.length
            }));
    }

    getHistoryGroupInfo(card) {
        const dateValue =
            card?.opportunityCreatedDate || card?.lastModifiedDate;
        const timeValue = this.toDateValue(dateValue);

        if (!timeValue) {
            return {
                key: 'unknown',
                label: 'Unknown Date',
                sortValue: 0
            };
        }

        const localDate = this.convertUtcToUserLocal(dateValue);
        const label = new Intl.DateTimeFormat('en-US', {
            month: 'long',
            year: 'numeric'
        }).format(localDate);
        const groupDate = new Date(
            localDate.getFullYear(),
            localDate.getMonth(),
            1
        );

        return {
            key: `${localDate.getFullYear()}-${localDate.getMonth() + 1}`,
            label,
            sortValue: groupDate.getTime()
        };
    }

    normalizeShippingAddress(record) {
        const shippingAttn = this.normalizeAddressValue(record?.shippingAttn);
        const shippingSiteName = this.normalizeAddressValue(
            record?.shippingSiteName || record?.serviceSiteName
        );
        const shippingStreet = this.normalizeAddressValue(record?.shippingStreet);
        const shippingCity = this.normalizeAddressValue(record?.shippingCity);
        const shippingState = this.normalizeAddressValue(record?.shippingState);
        const shippingPostalCode = this.normalizeAddressValue(record?.shippingPostalCode);
        const shippingCountry = this.normalizeAddressValue(record?.shippingCountry);
        const shippingFullAddress = this.composeFullAddress({
            street: shippingStreet,
            city: shippingCity,
            state: shippingState,
            postalCode: shippingPostalCode,
            country: shippingCountry
        });
        const hasCompleteShippingAddress = this.hasCompleteAddress({
            street: shippingStreet,
            city: shippingCity,
            state: shippingState,
            postalCode: shippingPostalCode,
            country: shippingCountry
        });

        return {
            shippingAttn,
            shippingSiteName,
            shippingStreet,
            shippingCity,
            shippingState,
            shippingPostalCode,
            shippingCountry,
            shippingFullAddress,
            hasShippingAddress: Boolean(shippingAttn) || Boolean(shippingFullAddress),
            hasShippingAttn: Boolean(shippingAttn),
            hasCompleteShippingAddress
        };
    }

    hasStreetValue(record) {
        return Boolean(this.normalizeAddressValue(record?.street));
    }

    hasScheduleAddress(record) {
        if (!record) {
            return false;
        }

        const street = this.normalizeAddressValue(record.street);
        const city = this.normalizeAddressValue(record.city);
        const state = this.normalizeAddressValue(record.state);
        const postalCode = this.normalizeAddressValue(record.postalCode);

        return Boolean(street || city || state || postalCode);
    }

    hasCompleteAddress(record) {
        if (!record) {
            return false;
        }

        const street = this.normalizeAddressValue(record.street);
        const city = this.normalizeAddressValue(record.city);
        const state = this.normalizeAddressValue(record.state);
        const postalCode = this.normalizeAddressValue(record.postalCode);
        const country = this.normalizeAddressValue(record.country);

        return (
            Boolean(street) &&
            Boolean(city) &&
            Boolean(state) &&
            Boolean(postalCode) &&
            Boolean(country)
        );
    }

    hasCompleteShippingAddress(record) {
        if (!record) {
            return false;
        }

        return this.hasCompleteAddress({
            street: record.shippingStreet,
            city: record.shippingCity,
            state: record.shippingState,
            postalCode: record.shippingPostalCode,
            country: record.shippingCountry
        });
    }

    getAddressBlockedReason(record) {
        if (this.hasScheduleAddress(record)) {
            return null;
        }

        return 'Enter an address before scheduling.';
    }

    showAddressRequiredHelp(cardId = null) {
        this.addressHelpCardId = cardId;
        this.safeClearTimeout(this._addressHelpTimeout);

        this._addressHelpTimeout = this.safeSetTimeout(() => {
            this.addressHelpCardId = null;
        }, 4000);

        this.showToast(
            'Add address',
            'Enter an address before scheduling.',
            'warning'
        );
    }

    get quoteWorkOrders() {
        if (!this.unscheduledWorkOrders) {
            return [];
        }

        return this.unscheduledWorkOrders
            .filter(wo => this.isQuoteStatus(this.resolveQuoteStatus(wo)))
            .map(wo => {
                const serviceAppointmentCount = wo.serviceAppointmentCount || 0;
                const base = {
                    ...wo,
                    cardId: `wo-${wo.workOrderId}`,
                    appointmentId: null,
                    hasAppointment: false,
                    completedVisitCount: wo.completedVisitCount || 0,
                    serviceAppointmentCount,
                    visitNumber: serviceAppointmentCount,
                    visitLabel:
                        serviceAppointmentCount > 0
                            ? `Visit ${serviceAppointmentCount}`
                            : null,
                    workOrderId: wo.workOrderId,
                    workOrderStatus: wo.workOrderStatus || wo.status,
                    workOrderStage: wo.workOrderStage || wo.stage,
                    workOrderNumber: wo.workOrderNumber,
                    workOrderSubject: wo.workOrderSubject || wo.subject,
                    accountId: wo.accountId,
                    accountName: wo.accountName,
                    accountNameFreeText: wo.accountNameFreeText,
                    street: wo.street,
                    city: wo.city,
                    state: wo.state,
                    postalCode: wo.postalCode,
                    country: wo.country,
                    fullAddress: wo.fullAddress,
                    hasFullAddress: this.hasStreetValue(wo),
                    opportunityTrackingNumber: wo.opportunityTrackingNumber || null,
                    opportunityNumber: wo.opportunityNumber || null,
                    opportunityRecordType: wo.opportunityRecordType,
                    opportunityStage: wo.opportunityStage || null,
                    showOpportunityStage: this.shouldShowOpportunityStage(wo),
                    opportunityStageClass: this.getOpportunityStageClass(wo),
                    showOpportunityMeta: this.shouldShowOpportunityMeta(wo),
                    quoteLineItems: this.normalizeQuoteLineItems(
                        wo.quoteLineItems
                    ),
                    quoteAttachmentUrl: wo.quoteAttachmentDownloadUrl || null,
                    quoteAttachmentDocumentId:
                        wo.quoteAttachmentDocumentId || null,
                    hasQuoteAttachment: Boolean(
                        wo.hasQuoteAttachment ||
                            wo.quoteAttachmentDownloadUrl ||
                            wo.quoteAttachmentDocumentId
                    ),
                    showGoToFilesAction: Boolean(
                        wo.quoteAttachmentDownloadUrl ||
                        (this.isQuoteAttachedAppointment(wo) && this.isProbeRepairRecord(wo))
                    ),
                    showQuoteActions:
                        this.resolveQuoteStatus(wo) === 'Quote Sent' ||
                        this.resolveQuoteStatus(wo) === 'Ready to Ship' ||
                        this.isQuoteAttachedAppointment(wo),
                    showMarkQuoteSentAction:
                        this.shouldShowMarkQuoteSentAction(wo),
                    showMarkPoAttachedAction: this.shouldShowMarkPoAttached(wo),
                    showCancelSaleAction: this.shouldShowCancelSaleAction(wo),
                    showRepairApprovedAction:
                        this.shouldShowRepairApprovedAction(wo),
                    showExchangeApprovalAction:
                        this.shouldShowExchangeApprovalAction(wo),
                    showRepairApprovalActions:
                        this.shouldShowRepairApprovalActions(wo),
                    showConfirmShippingAction:
                        this.shouldShowConfirmShippingAction(wo),
                    showMarkRepairSentAction:
                        this.shouldShowMarkRepairSentAction(wo),
                    dateQuoteSentToCustomer: wo.dateQuoteSentToCustomer || null,
                    quoteSentDateDisplay: this.formatDateDisplay(wo.dateQuoteSentToCustomer),
                    showQuoteSentDate: Boolean(
                        wo.dateQuoteSentToCustomer &&
                        this.resolveQuoteStatus(wo) === 'Quote Sent'
                    ),
                    isExpanded: Boolean(wo.isExpanded),
                    workTypeName: 'Work Order',
                    workTypeClass: 'sfs-worktype'
                };

                const poState = this.buildPoNumberState(base);
                return this.applyAccountPresentation({
                    ...base,
                    ...poState,
                    ...this.buildServiceSiteState(base)
                });
            });
    }

    get unscheduledListItems() {
        const workOrders = this.sortUnscheduledWorkOrders(
            this.unscheduledWorkOrders || []
        );

        const filteredWorkOrders = this.filterByWorkOrderNumber(workOrders);

        return filteredWorkOrders.map(wo => {
            const typeClass = this.getEventTypeClass(wo.workTypeName);
            const completedVisitCount = wo.completedVisitCount || 0;
            const serviceAppointmentCount = wo.serviceAppointmentCount || 0;
            const visitNumber = serviceAppointmentCount;
            const accountDisplayName = this.getWorkOrderAccountName(wo);
            const base = {
                ...wo,
                cardId: wo.cardId || `wo-${wo.workOrderId}`,
                workOrderId: wo.workOrderId,
                workOrderSubject: wo.workOrderSubject || wo.subject,
                workOrderStatus: wo.workOrderStatus || wo.status,
                workOrderStage: wo.workOrderStage || wo.stage,
                workOrderNumber: wo.workOrderNumber,
                workTypeName: wo.workTypeName,
                workTypeClass: `sfs-worktype ${typeClass || ''}`.trim(),
                completedVisitCount,
                serviceAppointmentCount,
                visitNumber,
                visitLabel:
                    serviceAppointmentCount > 0
                        ? `Visit ${serviceAppointmentCount}`
                        : null,
                opportunityTrackingNumber: wo.opportunityTrackingNumber || null,
                opportunityNumber: wo.opportunityNumber || null,
                opportunityRecordType: wo.opportunityRecordType,
                opportunityStage: wo.opportunityStage || null,
                showOpportunityStage: this.shouldShowOpportunityStage(wo),
                opportunityStageClass: this.getOpportunityStageClass(wo),
                showOpportunityMeta: this.shouldShowOpportunityMeta(wo),
                quoteLineItems: this.normalizeQuoteLineItems(wo.quoteLineItems),
                quoteAttachmentUrl: wo.quoteAttachmentDownloadUrl || null,
                quoteAttachmentDocumentId: wo.quoteAttachmentDocumentId || null,
                hasQuoteAttachment: Boolean(
                    wo.hasQuoteAttachment ||
                        wo.quoteAttachmentDownloadUrl ||
                        wo.quoteAttachmentDocumentId
                ),
                showGoToFilesAction: Boolean(
                    wo.quoteAttachmentDownloadUrl ||
                    (this.isQuoteAttachedAppointment(wo) && this.isProbeRepairRecord(wo))
                ),
                showQuoteActions:
                    this.resolveQuoteStatus(wo) === 'Quote Sent' ||
                    this.resolveQuoteStatus(wo) === 'Ready to Ship' ||
                    this.isQuoteAttachedAppointment(wo),
                showMarkQuoteSentAction: this.shouldShowMarkQuoteSentAction(wo),
                showMarkPoAttachedAction: this.shouldShowMarkPoAttached(wo),
                showCancelSaleAction: this.shouldShowCancelSaleAction(wo),
                showRepairApprovedAction:
                    this.shouldShowRepairApprovedAction(wo),
                showExchangeApprovalAction:
                    this.shouldShowExchangeApprovalAction(wo),
                showRepairApprovalActions:
                    this.shouldShowRepairApprovalActions(wo),
                showConfirmShippingAction:
                    this.shouldShowConfirmShippingAction(wo),
                showMarkRepairSentAction:
                    this.shouldShowMarkRepairSentAction(wo),
                dateQuoteSentToCustomer: wo.dateQuoteSentToCustomer || null,
                quoteSentDateDisplay: this.formatDateDisplay(wo.dateQuoteSentToCustomer),
                showQuoteSentDate: Boolean(
                    wo.dateQuoteSentToCustomer &&
                    this.resolveQuoteStatus(wo) === 'Quote Sent'
                ),
                hasAppointment: false,
                accountDisplayName:
                    accountDisplayName || wo.accountNameFreeText || 'Unassigned account'
            };
            return {
                ...base,
                ...this.buildPoNumberState(base),
                ...this.buildServiceSiteState(base)
            };
        });
    }

    filterByWorkOrderNumber(items = []) {
        if (!this.hasInteractedWithWorkOrderNumberFilter) {
            return items;
        }

        const normalizedFilter = this.normalizedWorkOrderNumberFilter;

        if (!normalizedFilter) {
            return items;
        }

        return items.filter(item => {
            const workOrderNumber = (item.workOrderNumber || '')
                .toString()
                .toLowerCase();
            const opportunityNumber = (
                item.opportunityNumber ||
                item.opportunityTrackingNumber ||
                ''
            )
                .toString()
                .toLowerCase();
            const opportunityName = (item.opportunityName || '')
                .toString()
                .toLowerCase();
            const subject = (
                item.workOrderSubject ||
                item.subject ||
                ''
            )
                .toString()
                .toLowerCase();
            const accountName = (
                item.accountDisplayName ||
                item.accountName ||
                item.accountNameFreeText ||
                ''
            )
                .toString()
                .toLowerCase();
            const systemSerialNumber = (item.systemSerialNumber || '')
                .toString()
                .toLowerCase();
            const serviceSiteName = (item.serviceSiteName || '')
                .toString()
                .toLowerCase();
            const trackingNumber = (
                item.trackingNumber ||
                item.workOrderTrackingNumber ||
                ''
            )
                .toString()
                .toLowerCase();
            const poNumber = (item.poNumber || '')
                .toString()
                .toLowerCase();
            const customerId = (
                item.customerId ||
                item.customerID ||
                item.customerNumber ||
                ''
            )
                .toString()
                .toLowerCase();
            const lineItemPartName = this.normalizeLineItemPartSearch(item);

            if (
                !workOrderNumber &&
                !opportunityNumber &&
                !opportunityName &&
                !subject &&
                !accountName &&
                !systemSerialNumber &&
                !serviceSiteName &&
                !trackingNumber &&
                !poNumber &&
                !customerId &&
                !lineItemPartName
            ) {
                return false;
            }

            return (
                workOrderNumber.includes(normalizedFilter) ||
                opportunityNumber.includes(normalizedFilter) ||
                opportunityName.includes(normalizedFilter) ||
                subject.includes(normalizedFilter) ||
                accountName.includes(normalizedFilter) ||
                systemSerialNumber.includes(normalizedFilter) ||
                serviceSiteName.includes(normalizedFilter) ||
                trackingNumber.includes(normalizedFilter) ||
                poNumber.includes(normalizedFilter) ||
                customerId.includes(normalizedFilter) ||
                lineItemPartName.includes(normalizedFilter)
            );
        });
    }

    filterByOpportunityTypeValue(items = [], filterValue) {

        if (!filterValue || filterValue === 'all') {
            return items;
        }

        const matchesRecordType = recordType => {
            const normalizedRecordType = (recordType || '')
                .toString()
                .toLowerCase();

            switch (filterValue) {
                case 'breakFix':
                    return (
                        normalizedRecordType.includes('break-fix') ||
                        normalizedRecordType.includes('break fix') ||
                        normalizedRecordType.includes('parts sale')
                    );
                case 'probeRepair':
                    return normalizedRecordType.includes('probe repair');
                case 'probeSale':
                    return normalizedRecordType.includes('probe sale');
                default:
                    return true;
            }
        };

        return items.filter(item =>
            matchesRecordType(item.opportunityRecordType)
        );
    }

    getOpportunityTypeTotalCount(typeValue) {
        const baseMode = this.listModePrimaryTab === 'scheduled' ? 'my' : 'unscheduled';
        const workOrderFilteredList = this.filterByOpportunityTypeValue(
            this.getFilteredListModeItems(baseMode, 'all'),
            typeValue
        );
        return this.filterListModeItemsByPrimaryTab(
            workOrderFilteredList,
            this.listModePrimaryTab
        ).reduce((uniqueKeys, item) => {
            const uniqueWorkOrderNumber = this.getWorkOrderUniqueKey(item);

            if (uniqueWorkOrderNumber) {
                uniqueKeys.add(uniqueWorkOrderNumber);
            }

            return uniqueKeys;
        }, new Set()).size;
    }

    getWorkOrderUniqueKey(item) {
        return (
            item?.workOrderNumber ||
            item?.relatedWorkOrderNumber ||
            item?.workOrderId ||
            ''
        )
            .toString()
            .trim()
            .toLowerCase();
    }

    getOpportunityTypeAlertModes(typeValue) {
        if (typeValue === 'probeRepair') {
            return [
                'probePendingApproval',
                'probeRepairDeclined',
                'confirmShipping'
            ];
        }

        return [
            'quoteAttached',
            'quoteSent',
            'generateFsr',
            'reGenerateFsr',
            'partsProbeShipped'
        ];
    }

    getOpportunityTypeModeCountForPrimaryTab(listMode, typeValue, tabValue) {
        const baseList = this.getListModeBaseList(listMode);
        const opportunityFilteredList = this.filterByOpportunityTypeValue(
            baseList,
            typeValue
        );
        const nonPreventativeList = this.filterOutPreventativeMaintenance(
            opportunityFilteredList
        );
        const nonTerminalList = this.filterOutTerminalWorkOrders(nonPreventativeList);
        const workOrderFilteredList = this.filterByWorkOrderNumber(nonTerminalList);
        return this.filterListModeItemsByPrimaryTab(workOrderFilteredList, tabValue)
            .length;
    }

    filterOutPreventativeMaintenance(items = []) {
        return items.filter(
            item => !this.isPreventativeMaintenanceWorkType(item)
        );
    }

    isQuoteAttachedAppointment(appt) {
        const resolvedStatus = this.resolveQuoteStatus(appt);
        const status = (resolvedStatus || appt?.workOrderStatus || appt?.status || '')
            .toLowerCase();
        const stages = [
            appt?.workOrderStage || appt?.stage || '',
            this.isProbeRepairRecord(appt) ? appt?.opportunityStage || '' : ''
        ]
            .filter(Boolean)
            .map(value => value.toLowerCase());

        if (stages.includes('quote attached')) {
            return true;
        }

        return status.startsWith('quote attached');
    }

    shouldShowMarkQuoteSentAction(record) {
        if (!record) {
            return false;
        }

        if (this.isProbeRepairRecord(record)) {
            return false;
        }

        const status = this.resolveQuoteStatus(record).toLowerCase();
        if (status === 'ready to ship') {
            return false;
        }

        return this.isQuoteAttachedAppointment(record);
    }

    shouldShowMarkRepairSentAction(record) {
        if (!record) {
            return false;
        }

        if (!this.isProbeRepairRecord(record)) {
            return false;
        }

        return this.isQuoteAttachedAppointment(record);
    }

    shouldShowMarkPoAttached(record) {
        if (!record) {
            return false;
        }

        const status = this.resolveQuoteStatus(record).toLowerCase();
        if (status.startsWith('quote attached') && this.isProbeRepairRecord(record)) {
            return false;
        }
        return status === 'quote sent' || status.startsWith('quote attached');
    }

    shouldShowCancelSaleAction(record) {
        if (!record) {
            return false;
        }

        const status = this.resolveQuoteStatus(record).toLowerCase();
        return status === 'quote sent';
    }

    normalizeStatusLabel(value) {
        return (value || '').trim().toLowerCase();
    }

    toDateValue(value) {
        if (!value) {
            return 0;
        }

        const date = new Date(value);
        return Number.isNaN(date.getTime()) ? 0 : date.getTime();
    }

    parseDateOnlyValue(value) {
        if (!value) {
            return null;
        }

        if (value instanceof Date) {
            const date = new Date(
                value.getFullYear(),
                value.getMonth(),
                value.getDate()
            );
            return Number.isNaN(date.getTime()) ? null : date;
        }

        if (typeof value === 'string') {
            const match = value.match(/^(\d{4})-(\d{2})-(\d{2})/);
            if (match) {
                const year = Number(match[1]);
                const month = Number(match[2]) - 1;
                const day = Number(match[3]);
                const date = new Date(year, month, day);
                return Number.isNaN(date.getTime()) ? null : date;
            }
        }

        const date = new Date(value);
        return Number.isNaN(date.getTime()) ? null : date;
    }

    formatDateDisplay(value) {
        const date = this.parseDateOnlyValue(value);
        if (!date) return null;
        return date.toLocaleDateString('en-US', { month: 'numeric', day: 'numeric', year: 'numeric' });
    }

    isPreventativeMaintenanceWorkType(item) {
        const workTypeName = (item?.workTypeName || '').toLowerCase();
        return (
            workTypeName === 'ppm' ||
            workTypeName.includes('preventative maintenance') ||
            workTypeName.includes('preventive maintenance')
        );
    }

    isInstallWorkType(item) {
        const workTypeName = (item?.workTypeName || '').toLowerCase();
        return workTypeName.includes('install');
    }

    shouldShowWorkTypePill(item) {
        const workTypeName = (item?.workTypeName || '').toLowerCase();
        if (!workTypeName) {
            return false;
        }

        return (
            this.isPreventativeMaintenanceWorkType(item) ||
            workTypeName.includes('preventative maintenance') ||
            workTypeName.includes('preventive maintenance') ||
            this.isInstallWorkType(item)
        );
    }

    isCompletedWorkOrder(item) {
        return (
            this.normalizeStatusLabel(item?.workOrderStatus) === 'completed wo'
        );
    }

    isCompletedOrCanceledWorkOrder(item) {
        const normalizedStatus = this.normalizeStatusLabel(
            item?.workOrderStatus || item?.status || ''
        );
        return (
            normalizedStatus === 'completed wo' ||
            normalizedStatus === 'completed work order' ||
            normalizedStatus === 'canceled' ||
            normalizedStatus === 'cancelled'
        );
    }

    isReadyForCloseStatus(item) {
        return (
            this.normalizeStatusLabel(
                item?.workOrderStatus || item?.status || ''
            ) === 'ready for close'
        );
    }

    isGenerateFsrStatus(item) {
        return (
            this.normalizeStatusLabel(
                item?.workOrderStatus || item?.status || ''
            ) === 'generate fsr'
        );
    }

    isReGenerateFsrStatus(item) {
        const normalizedStatus = this.normalizeStatusLabel(
            item?.workOrderStatus || item?.status || ''
        );
        return (
            normalizedStatus === 're-generate fsr' ||
            normalizedStatus === 'regenerate fsr' ||
            normalizedStatus === 're generate fsr'
        );
    }

    isNewStatus(item) {
        return (
            this.normalizeStatusLabel(
                item?.workOrderStatus || item?.status || ''
            ) === 'new'
        );
    }

    isUpdateNeededStatus(item) {
        return (
            this.normalizeStatusLabel(
                item?.workOrderStatus || item?.status || ''
            ) === 'update needed'
        );
    }

    filterOutTerminalWorkOrders(items) {
        return (items || []).filter(
            item =>
                !this.isTerminalStatus(
                    item?.workOrderStatus || item?.status || ''
                )
        );
    }

    isWithinPastDays(dateValue, days) {
        const timeValue = this.toDateValue(dateValue);
        if (!timeValue) {
            return false;
        }

        const now = Date.now();
        const windowMs = days * 24 * 60 * 60 * 1000;
        return timeValue >= now - windowMs && timeValue <= now;
    }

    isOnOrBeforeNextDays(dateValue, days) {
        const timeValue = this.toDateValue(dateValue);
        if (!timeValue) {
            return false;
        }

        const end = new Date();
        end.setHours(23, 59, 59, 999);
        end.setDate(end.getDate() + days);

        return timeValue <= end.getTime();
    }

    isAfterNextDays(dateValue, days) {
        const timeValue = this.toDateValue(dateValue);
        if (!timeValue) {
            return false;
        }

        const end = new Date();
        end.setHours(23, 59, 59, 999);
        end.setDate(end.getDate() + days);

        return timeValue > end.getTime();
    }

    getNextServiceDateValue(item) {
        const date = this.parseDateOnlyValue(item?.nextServiceDate);
        return date ? date.getTime() : 0;
    }
    
    isPreventativeMaintenanceInWindow(item) {
        const nextServiceDate = this.parseDateOnlyValue(item?.nextServiceDate);
        if (!nextServiceDate) {
            return false;
        }

        return this.isOnOrBeforeNextDays(nextServiceDate, 60);
    }

    hasScheduledServiceAppointment(item) {
        if (!item) {
            return false;
        }

        if (item.hasAppointment || item.appointmentId) {
            return true;
        }

        const visitScheduleDates = Array.isArray(item.visitScheduleDates)
            ? item.visitScheduleDates
            : [];
        const hasScheduledVisitDate = visitScheduleDates.some(value => {
            if (!value) {
                return false;
            }

            const parsed = new Date(value);
            return !Number.isNaN(parsed.getTime());
        });
        if (hasScheduledVisitDate) {
            return true;
        }

        return (item.serviceAppointmentCount || 0) > 0;
    }

    isScheduledPreventativeMaintenanceItem(item) {
        return this.getPmScheduledFilterDiagnostics(item).isEligible;
    }


    getPmScheduledFilterDiagnostics(item) {
        const hasScheduledAppointment = this.hasScheduledServiceAppointment(item);
        const isCompletedOrCanceled = this.isCompletedOrCanceledWorkOrder(item);
        const isReadyForClose = this.isReadyForCloseStatus(item);

        return {
            isEligible:
                hasScheduledAppointment &&
                !isCompletedOrCanceled &&
                !isReadyForClose,
            hasScheduledAppointment,
            isCompletedOrCanceled,
            isReadyForClose
        };
    }

    logPreventativeMaintenanceScheduledFilter(items) {
        if (!this.debugMode || !Array.isArray(items) || items.length === 0) {
            return;
        }

        const dropped = items
            .map(item => ({
                item,
                diagnostics: this.getPmScheduledFilterDiagnostics(item)
            }))
            .filter(entry => !entry.diagnostics.isEligible)
            .map(entry => ({
                workOrderNumber: entry.item?.workOrderNumber || entry.item?.name,
                workOrderId: entry.item?.workOrderId || entry.item?.id,
                hasScheduledAppointment: entry.diagnostics.hasScheduledAppointment,
                isCompletedOrCanceled: entry.diagnostics.isCompletedOrCanceled,
                isReadyForClose: entry.diagnostics.isReadyForClose
            }));

        if (dropped.length === 0) {
            return;
        }

        // eslint-disable-next-line no-console
        console.debug('[PM Scheduled Filter] Excluded work orders', dropped);
    }

    getPreventativeMaintenanceTabItems(tabValue, items) {
        switch (tabValue) {
            case 'scheduled':
                this.logPreventativeMaintenanceScheduledFilter(items);
                return items.filter(item =>
                    this.isScheduledPreventativeMaintenanceItem(item)
                );
            case 'readyForClose':
                return items.filter(item => this.isReadyForCloseStatus(item));
            case 'completed':
                return items.filter(
                    item =>
                        this.isCompletedWorkOrder(item) &&
                        this.isWithinPastDays(
                            item.workOrderLastModifiedDate ||
                                item.serviceAppointmentLastModifiedDate,
                            14
                        )
                );
            case 'unscheduledAfter30':
                return items.filter(item => {
                    if (
                        this.hasScheduledServiceAppointment(item) ||
                        this.isCompletedOrCanceledWorkOrder(item)
                    ) {
                        return false;
                    }

                    const nextServiceDate = this.parseDateOnlyValue(
                        item?.nextServiceDate
                    );
                    if (!nextServiceDate) {
                        return false;
                    }

                    return this.isAfterNextDays(nextServiceDate, 30);
                });
            case 'unscheduledNext30':
            default:
                return items.filter(item => {
                    if (
                        this.hasScheduledServiceAppointment(item) ||
                        this.isCompletedOrCanceledWorkOrder(item)
                    ) {
                        return false;
                    }

                    const nextServiceDate = this.parseDateOnlyValue(
                        item?.nextServiceDate
                    );
                    if (!nextServiceDate) {
                        return false;
                    }

                    return this.isOnOrBeforeNextDays(nextServiceDate, 30);
                });
        }
    }

    isRecentlyCreatedWorkOrder(item) {
        const createdDate = item?.workOrderCreatedDate;
        return this.isWithinLastHours(createdDate, 24);
    }

    isRecentlyModifiedByCurrentUser(item) {
        if (!item || !this.currentUserId) {
            return false;
        }

        const lastModified = this.getLastModifiedMetadata(item);
        if (!lastModified || !lastModified.date || !lastModified.byId) {
            return false;
        }

        if (lastModified.byId !== this.currentUserId) {
            return false;
        }

        return this.isWithinLastHours(lastModified.date, 24);
    }

    getLastModifiedMetadata(item) {
        if (!item) {
            return null;
        }

        if (item.hasAppointment) {
            const appointmentModified = {
                date: item.serviceAppointmentLastModifiedDate,
                byId: item.serviceAppointmentLastModifiedById
            };
            const workOrderModified = {
                date: item.workOrderLastModifiedDate,
                byId: item.workOrderLastModifiedById
            };

            const candidates = [appointmentModified, workOrderModified].filter(
                candidate => candidate.date && candidate.byId
            );

            if (candidates.length === 0) {
                return null;
            }

            return candidates.reduce((latest, candidate) => {
                const latestTime = this.toDateValue(latest.date);
                const candidateTime = this.toDateValue(candidate.date);
                return candidateTime > latestTime ? candidate : latest;
            });
        }

        return {
            date: item.workOrderLastModifiedDate,
            byId: item.workOrderLastModifiedById
        };
    }

    getLastModifiedTimeValue(item) {
        const lastModified = this.getLastModifiedMetadata(item);
        return lastModified ? this.toDateValue(lastModified.date) : 0;
    }

    getCreatedTimeValue(item) {
        return this.toDateValue(item?.workOrderCreatedDate);
    }

    isWithinLastHours(value, hours) {
        if (!value) {
            return false;
        }

        const timestamp = this.toDateValue(value);
        if (!timestamp || !hours || hours <= 0) {
            return false;
        }

        const now = Date.now();
        const lowerBound = now - (hours * 60 * 60 * 1000);
        return timestamp >= lowerBound && timestamp <= now;
    }

    isDateToday(value) {
        const timestamp = this.toDateValue(value);
        if (!timestamp) {
            return false;
        }

        const date = new Date(timestamp);
        const now = new Date();
        return (
            date.getFullYear() === now.getFullYear() &&
            date.getMonth() === now.getMonth() &&
            date.getDate() === now.getDate()
        );
    }

    isTerminalStatus(statusLabel) {
        const normalized = this.normalizeStatusLabel(statusLabel);
        return this.journeyTerminalStatuses.some(
            terminal => this.normalizeStatusLabel(terminal) === normalized
        );
    }

    getTerminalLabel(statusLabel) {
        if (this.isTerminalStatus(statusLabel)) {
            return statusLabel || 'Closed';
        }
        return 'Closed';
    }

    getDetourKind(record) {
        const statusLabel = record.workOrderStatus || record.status || '';
        const normalized = this.normalizeStatusLabel(statusLabel);

        if (
            normalized === 'need quote' ||
            normalized === 'quote attached' ||
            normalized === 'quote sent'
        ) {
            return 'quote';
        }

        if (normalized === 'parts requested') {
            return 'parts';
        }

        if (
            normalized === 'po requested' ||
            normalized === 'ready to ship' ||
            normalized === 'pending shipment' ||
            normalized === 'parts/probe shipped' ||
            normalized === 'parts probe shipped'
        ) {
            if (
                this.isQuoteAttachedAppointment(record) ||
                (record.quoteLineItems && record.quoteLineItems.length) ||
                record.hasQuoteAttachment
            ) {
                return 'quote';
            }

            if (record.somePartsEnRoute || record.allPartsEnRoute) {
                return 'parts';
            }

            // Default to quote path for PO states when we cannot infer context.
            return 'quote';
        }

        return null;
    }

    buildDetourModel(record, normalizedStatus) {
        const kind = this.getDetourKind(record);

        if (!kind || !this.journeyDetours[kind]) {
            return {
                kind: null,
                label: '',
                steps: [],
                hasDetour: false,
                detourComplete: false,
                activeStep: null,
                detourNext: null
            };
        }

        const detourDef = this.journeyDetours[kind];
        const normalizedSteps = detourDef.steps.map(step =>
            this.normalizeStatusLabel(step)
        );
        const currentIndex = normalizedSteps.indexOf(normalizedStatus);
        const steps = detourDef.steps.map((stepLabel, index) => {
            const normalizedStep = normalizedSteps[index];
            const isCurrent = currentIndex === index;
            const isDone = currentIndex > index;

            const variant = isCurrent ? 'current' : isDone ? 'done' : 'upcoming';

            return {
                id: `${kind}-${normalizedStep}`,
                label: stepLabel,
                variant,
                className: this.getJourneyStepClass(
                    {
                        id: `${kind}-${normalizedStep}`,
                        label: stepLabel,
                        variant
                    },
                    true
                )
            };
        });

        const activeStep = steps.find(step => step.variant === 'current');
        const detourNext =
            steps.find(step => step.variant === 'upcoming') ||
            steps[steps.length - 1];
        const detourComplete = currentIndex >= steps.length - 1 && currentIndex !== -1;

        return {
            kind,
            label: detourDef.label,
            steps,
            hasDetour: true,
            activeStep,
            detourNext,
            detourComplete
        };
    }

    getMainStepIndex(normalizedStatus, detourComplete) {
        if (this.isTerminalStatus(normalizedStatus)) {
            return this.journeyMainFlow.length;
        }

        if (normalizedStatus === 'ready for close') {
            return Math.max(this.journeyMainFlow.length - 1, 0);
        }

        if (normalizedStatus === 'generate fsr') {
            return Math.max(this.journeyMainFlow.length - 2, 0);
        }

        if (
            normalizedStatus === 're-generate fsr' ||
            normalizedStatus === 'regenerate fsr' ||
            normalizedStatus === 're generate fsr'
        ) {
            return Math.max(this.journeyMainFlow.length - 2, 0);
        }

        if (
            normalizedStatus === 'in progress' ||
            normalizedStatus === 'ready to ship' ||
            normalizedStatus === 'on hold'
        ) {
            return 1;
        }

        if (detourComplete) {
            return 1;
        }

        return 0;
    }

    getJourneyStepClass(step, isDetour = false) {
        const base = isDetour
            ? 'sfs-journey__step sfs-journey__step_detour'
            : 'sfs-journey__step';
        const variant = step.variant ? ` sfs-journey__step_${step.variant}` : '';
        const paused = step.isPaused ? ' sfs-journey__step_paused' : '';
        const terminal = step.isTerminal ? ' sfs-journey__step_terminal' : '';
        return `${base}${variant}${paused}${terminal}`.trim();
    }

    buildMainJourneySteps(statusLabel, normalizedStatus, detourComplete) {
        const terminalLabel = this.getTerminalLabel(statusLabel);
        const steps = this.journeyMainFlow.map(flowLabel => ({
            id: this.normalizeStatusLabel(flowLabel).replace(/\s+/g, '-'),
            label: flowLabel
        }));

        steps.push({ id: 'terminal', label: terminalLabel, isTerminal: true });

        const currentIndex = this.getMainStepIndex(
            normalizedStatus,
            detourComplete
        );

        return steps.map((step, index) => {
            let variant = 'upcoming';
            if (index === currentIndex) {
                variant = 'current';
            } else if (index < currentIndex) {
                variant = 'done';
            }

            const isPaused = normalizedStatus === 'on hold' && index === currentIndex;

            return {
                ...step,
                variant,
                isPaused,
                className: this.getJourneyStepClass(
                    {
                        ...step,
                        variant,
                        isPaused
                    },
                    false
                )
            };
        });
    }

    getNextStepLabelFromSteps(steps) {
        const upcoming = steps.find(step => step.variant === 'upcoming');
        if (upcoming) {
            return upcoming.label;
        }
        const current = steps.find(step => step.variant === 'current');
        if (current) {
            return current.label;
        }
        return steps.length ? steps[steps.length - 1].label : '';
    }

    buildCompactJourneySummary(steps) {
        if (!steps || !steps.length) {
            return {
                visibleSteps: [],
                completedBefore: 0,
                upcomingAfter: 0
            };
        }

        const currentIndex = steps.findIndex(step => step.variant === 'current');
        const focusIndex = currentIndex === -1 ? 0 : currentIndex;
        const startIndex = Math.max(0, focusIndex - 1);
        const endIndex = Math.min(steps.length - 1, focusIndex + 1);

        const completedBefore = Math.max(0, startIndex);
        const upcomingAfter = Math.max(0, steps.length - 1 - endIndex);

        const visibleSteps = steps.slice(startIndex, endIndex + 1).map(step => {
            const variant = step.variant || 'upcoming';
            return {
                ...step,
                compactClass: `sfs-journey__chip sfs-journey__chip_${variant}`
            };
        });

        return {
            visibleSteps,
            completedBefore,
            upcomingAfter
        };
    }

    buildWorkOrderJourney(record) {
        const statusLabel = (record.workOrderStatus || record.status || 'New').trim();
        const normalizedStatus = this.normalizeStatusLabel(statusLabel);
        const detour = this.buildDetourModel(record, normalizedStatus);
        const mainSteps = this.buildMainJourneySteps(
            statusLabel,
            normalizedStatus,
            detour.detourComplete
        );

        const progressSteps =
            detour.hasDetour && !detour.detourComplete && detour.steps.length
                ? detour.steps
                : mainSteps;
        const completedSteps = progressSteps.filter(step => step.variant === 'done').length;
        const activeIndex = progressSteps.findIndex(step => step.variant === 'current');
        const segmentCount = Math.max(progressSteps.length - 1, 1);
        const progressPortion = completedSteps + (activeIndex >= 0 ? 0.5 : 0);
        const progressPercent = Math.min(
            100,
            Math.max(0, Math.round((progressPortion / segmentCount) * 100))
        );
        const progressLabel = `${completedSteps} of ${progressSteps.length} steps`;
        const stepsForSummary =
            detour.hasDetour && !detour.detourComplete && detour.steps.length
                ? detour.steps
                : mainSteps;
        const compactSummary = this.buildCompactJourneySummary(stepsForSummary);

        const detourActiveLabel =
            detour.hasDetour && detour.activeStep ? detour.activeStep.label : '';
        const useOpportunityStage =
            this.shouldUseOpportunityStageForProbeRepair(record);
        const currentLabel = useOpportunityStage
            ? (record.opportunityStage || '').trim() || statusLabel || 'New'
            : detourActiveLabel || statusLabel || 'New';

        let nextLabel = '';
        if (detour.hasDetour && !detour.detourComplete && detour.detourNext) {
            nextLabel = detour.detourNext.label;
        } else {
            nextLabel = this.getNextStepLabelFromSteps(mainSteps);
        }

        const compactHint = `${currentLabel || 'Current'} • Next: ${
            nextLabel || 'TBD'
        }`;

        return {
            statusLabel: statusLabel || 'New',
            normalizedStatus,
            currentLabel,
            nextLabel,
            isOnHold: normalizedStatus === 'on hold',
            mainSteps,
            detour,
            hasDetour: detour.hasDetour,
            detourLabel: detour.label,
            detourKind: detour.kind,
            detourActiveLabel,
            compactHint,
            progressPercent,
            progressStyle: `width: ${progressPercent}%`,
            progressLabel,
            compactSummary
        };
    }

    normalizeQuoteLineItems(items) {
        if (!items) {
            return [];
        }

        return items.map(item => ({
            lineItemId: item.lineItemId || item.id,
            workOrderId: item.workOrderId,
            productName: item.productName || '—',
            description: item.description || '',
            quantity:
                item.quantity === 0 || item.quantity
                    ? item.quantity
                    : '',
            unitPrice: item.unitPrice,
            lineType: item.lineType || '',
            trackingNumber: item.trackingNumber || ''
        }));
    }

    groupQuoteLineItems(lines) {
        if (!lines || !lines.length) {
            return [];
        }

        const priority = [
            'Quote and Ship',
            'Part Assigned',
            'Part Enroute',
            'Action Needed',
            'Part Quoted'
        ];

        const groups = new Map();

        lines.forEach(line => {
            const label = (line?.lineType || '').trim() || 'Other';
            const key = label.toLowerCase();
            const priorityIndex = priority.findIndex(
                type => type.toLowerCase() === key
            );

            if (!groups.has(key)) {
                groups.set(key, {
                    key,
                    label,
                    priorityIndex:
                        priorityIndex === -1 ? priority.length : priorityIndex,
                    lines: []
                });
            }

            groups.get(key).lines.push({
                ...line,
                lineTypeLabel: label || '—'
            });
        });

        return Array.from(groups.values())
            .sort((a, b) => {
                if (a.priorityIndex === b.priorityIndex) {
                    return a.label.localeCompare(b.label);
                }

                return a.priorityIndex - b.priorityIndex;
            })
            .map(({ priorityIndex, ...rest }) => rest);
    }

    shouldShowOpportunityStage(record) {
        if (!record) {
            return false;
        }

        return (
            record.opportunityRecordType === 'Probe Repair Opportunity' &&
            Boolean(record.opportunityStage)
        );
    }

    shouldShowOpportunityMeta(record) {
        if (!record) {
            return false;
        }

        return (
            Boolean(record.opportunityNumber) ||
            this.shouldShowOpportunityStage(record)
        );
    }

    resolveTrackingNumber(record, hasLineItemTracking) {
        if (!record || hasLineItemTracking) {
            return null;
        }

        const isWarrantyBillingType =
            String(record.billingType || '').toLowerCase() === 'warranty';

        return (
            record.latestServiceAppointmentTrackingNumber ||
            record.serviceAppointmentTrackingNumber ||
            record.workOrderTrackingNumber ||
            (isWarrantyBillingType ? null : record.opportunityTrackingNumber) ||
            null
        );
    }

    handleCopyTracking(event) {
        const trackingNumber =
            event?.detail?.tracking ||
            event?.currentTarget?.dataset?.tracking ||
            event?.target?.dataset?.tracking ||
            null;

        if (!trackingNumber) {
            return;
        }

        this.copyTextToClipboard(trackingNumber);
    }

    copyTextToClipboard(value) {
        if (!value) {
            return;
        }

        const onError = () => {
            this.showToast(
                'Copy failed',
                'Unable to copy the tracking number.',
                'error'
            );
        };

        if (navigator?.clipboard?.writeText) {
            navigator.clipboard
                .writeText(value)
                .then(() =>
                    this.showToast(
                        'Copied',
                        'Tracking number copied to clipboard.',
                        'success'
                    )
                )
                .catch(onError);
            return;
        }

        try {
            const textarea = document.createElement('textarea');
            textarea.value = value;
            textarea.setAttribute('readonly', '');
            textarea.style.position = 'absolute';
            textarea.style.left = '-9999px';
            document.body.appendChild(textarea);
            textarea.select();
            document.execCommand('copy');
            document.body.removeChild(textarea);
            this.showToast(
                'Copied',
                'Tracking number copied to clipboard.',
                'success'
            );
        } catch (e) {
            onError();
        }
    }

    findAppointmentByCardId(cardId) {
        if (!cardId) {
            return null;
        }

        const search = list =>
            (list || []).find(
                item =>
                    item && (item.cardId === cardId || item.appointmentId === cardId)
            );

        return (
            search(this.visibleAppointments) ||
            search(this.appointments) ||
            search(this.preventativeMaintenanceAppointments) ||
            search(this.quoteWorkOrders) ||
            search(this.activeRecentWorkOrderCards) ||
            search(this.unscheduledWorkOrders) ||
            null
        );
    }

    findRecordByWorkOrderId(workOrderId) {
        if (!workOrderId) {
            return null;
        }

        const appointment = (this.appointments || []).find(
            appt => appt.workOrderId === workOrderId
        );
        if (appointment) {
            return appointment;
        }

        const unscheduled = (this.unscheduledWorkOrders || []).find(
            wo => wo.workOrderId === workOrderId
        );
        if (unscheduled) {
            return unscheduled;
        }

        return (this.quoteWorkOrders || []).find(
            wo => wo.workOrderId === workOrderId
        );
    }

    updateRecordsByWorkOrderId(workOrderId, updater) {
        if (!workOrderId || typeof updater !== 'function') {
            return;
        }

        const updateList = list => {
            if (!Array.isArray(list) || list.length === 0) {
                return list;
            }

            const itemIndex = list.findIndex(
                item => item && item.workOrderId === workOrderId
            );

            if (itemIndex === -1) {
                return list;
            }

            const updatedList = [...list];
            updatedList[itemIndex] = updater(updatedList[itemIndex]);
            return updatedList;
        };

        this.appointments = updateList(this.appointments);
        this.unscheduledWorkOrders = updateList(this.unscheduledWorkOrders);

        if (
            this.selectedAppointment &&
            this.selectedAppointment.workOrderId === workOrderId
        ) {
            this.selectedAppointment = updater(this.selectedAppointment);
        }
    }

    startPoNumberEdit(workOrderId) {
        const record = this.findRecordByWorkOrderId(workOrderId);
        if (!record) {
            return;
        }

        this.poNumberModalWorkOrderId = workOrderId;
        this.poNumberModalValue = this.normalizePoNumberValue(record.poNumber);
        this.isPoNumberModalOpen = true;
    }

    cancelPoNumberEdit(workOrderId) {
        if (!workOrderId || this.poNumberModalWorkOrderId === workOrderId) {
            this.closePoNumberModal();
            return;
        }

        clearTimeout(this._poNumberInlineDebounceTimer);
        this._poNumberInlinePending = null;

        const record = this.findRecordByWorkOrderId(workOrderId);
        if (!record) {
            return;
        }

        const draft = this.normalizePoNumberValue(record.poNumber);
        this.updateRecordsByWorkOrderId(workOrderId, item => ({
            ...item,
            isEditingPoNumber: false,
            poNumberDraft: draft
        }));
    }

    closePoNumberModal() {
        clearTimeout(this._poNumberModalDebounceTimer);
        this._poNumberModalPending = null;
        this.isPoNumberModalOpen = false;
        this.poNumberSaving = false;
        this.poNumberModalWorkOrderId = null;
        this.poNumberModalValue = '';
    }

    applyPoNumberUpdate(workOrderId, poNumber) {
        const cleanPo = this.normalizePoNumberValue(poNumber);
        this.updateRecordsByWorkOrderId(workOrderId, item => {
            const updated = {
                ...item,
                poNumber: cleanPo,
                isEditingPoNumber: false,
                poNumberDraft: cleanPo
            };
            return {
                ...updated,
                ...this.buildPoNumberState(updated)
            };
        });
    }

    startServiceSiteEdit(workOrderId) {
        const record = this.findRecordByWorkOrderId(workOrderId);
        if (!record) {
            return;
        }
        this.serviceSiteModalWorkOrderId = workOrderId;
        this.serviceSiteModalValue = record.serviceSiteName || '';
        this.isServiceSiteModalOpen = true;
    }

    closeServiceSiteModal() {
        clearTimeout(this._serviceSiteModalDebounceTimer);
        this._serviceSiteModalPending = null;
        this.isServiceSiteModalOpen = false;
        this.serviceSiteModalWorkOrderId = null;
        this.serviceSiteModalValue = '';
    }

    applyServiceSiteUpdate(workOrderId, name) {
        this.updateRecordsByWorkOrderId(workOrderId, item => ({
            ...item,
            serviceSiteName: name,
            serviceSiteDisplay: name || 'Add service site',
            serviceSiteValueClass: name
                ? 'sfs-po-value'
                : 'sfs-po-value sfs-po-value_empty'
        }));
    }

    saveServiceSiteName(workOrderId) {
        if (this._serviceSiteModalPending !== null) {
            clearTimeout(this._serviceSiteModalDebounceTimer);
            this.serviceSiteModalValue = this._serviceSiteModalPending;
            this._serviceSiteModalPending = null;
        }

        const draft = (this.serviceSiteModalValue || '').trim();

        this.checkOnline();
        if (this.isOffline) {
            this.showToast(
                'Offline',
                'You must be online to update the service site name.',
                'warning'
            );
            return;
        }

        updateWorkOrderServiceSiteName({ workOrderId, serviceSiteName: draft })
            .then(updatedName => {
                this.applyServiceSiteUpdate(workOrderId, updatedName);
                this.closeServiceSiteModal();
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.debugInfo = {
                    note: 'Error calling updateWorkOrderServiceSiteName',
                    errorMessage: message
                };
                this.showToast('Error updating Service Site Name', message, 'error');
            });
    }

    getQuickScheduleBaseLabel(item) {
        return this.isSelectedVisitScheduled(item)
            ? 'Reschedule'
            : 'Quick schedule';
    }

    getQuickScheduleToggleLabel(item, isExpanded) {
        const baseLabel = this.getQuickScheduleBaseLabel(item);

        if (!isExpanded) {
            return baseLabel;
        }

        return this.isSelectedVisitScheduled(item)
            ? 'Hide reschedule'
            : 'Hide quick schedule';
    }

    getQuickScheduleDateLabel(item) {
        return this.isSelectedVisitScheduled(item)
            ? 'Reschedule Date/Time'
            : 'Schedule Date/Time';
    }

    getQuickScheduleActionLabel(item) {
        return this.isSelectedVisitScheduled(item) ? 'Reschedule' : 'Schedule';
    }

    getScheduleOnCalendarLabel(item) {
        return this.isSelectedVisitScheduled(item)
            ? 'Reschedule on Calendar'
            : 'Schedule on Calendar';
    }

    isSelectedVisitScheduled(item) {
        if (!item) {
            return false;
        }

        const totalVisits = item.serviceAppointmentCount || 0;
        if (totalVisits <= 0) {
            return Boolean(item.hasAppointment || item.appointmentId);
        }

        const selectedVisitNumber = this.getSelectedVisitNumber(item);
        return this.isVisitScheduled(item, selectedVisitNumber);
    }

    getSelectedVisitAppointmentId(item) {
        if (!item) {
            return null;
        }

        const selectedVisitNumber = this.getSelectedVisitNumber(item);
        if (!Number.isInteger(selectedVisitNumber) || selectedVisitNumber <= 0) {
            return item.appointmentId || null;
        }

        const visitAppointmentIds = Array.isArray(item.visitAppointmentIds)
            ? item.visitAppointmentIds
            : [];
        const selectedVisitAppointmentId =
            visitAppointmentIds[selectedVisitNumber - 1] || null;

        return selectedVisitAppointmentId;
    }

    getQuickScheduleValue(item) {
        if (!item) {
            return '';
        }

        const savedValue = item.cardId
            ? this.quickScheduleSelections[item.cardId]
            : null;

        if (savedValue) {
            return savedValue;
        }

        if (this.isSelectedVisitScheduled(item)) {
            return item.newStart || item.schedStart || '';
        }

        return '';
    }

    ensureQuickScheduleSelection(cardId, appt) {
        if (!cardId || this.quickScheduleSelections[cardId]) {
            return;
        }

        const fallbackValue =
            (appt && (appt.newStart || appt.schedStart)) || '';

        if (!fallbackValue) {
            return;
        }

        this.quickScheduleSelections = {
            ...this.quickScheduleSelections,
            [cardId]: fallbackValue
        };
    }

    normalizeWorkOrderDetail(workOrder) {
        if (!workOrder) {
            return null;
        }

        const typeClass = this.getEventTypeClass(workOrder.workTypeName);

        return {
            ...workOrder,
            appointmentId: null,
            workOrderId: workOrder.workOrderId,
            workOrderSubject: workOrder.workOrderSubject || workOrder.subject,
            workOrderStatus: workOrder.status,
            workOrderNumber: workOrder.workOrderNumber,
            workTypeName: workOrder.workTypeName,
            workTypeClass: `sfs-worktype ${typeClass || ''}`.trim(),
            schedStart: null,
            schedEnd: null,
            newStart: null,
            disableSave: true,
            isExpanded: false,
            hasAppointment: false,
            cardId: workOrder.cardId || `wo-${workOrder.workOrderId}`
        };
    }

    findAbsenceById(absenceId) {
        if (!absenceId || !this.absences) {
            return null;
        }

        return this.absences.find(a => a.absenceId === absenceId) || null;
    }

    get hasSelectedAppointment() {
        return this.selectedAppointment !== null;
    }

    get hasSelectedAbsence() {
        return this.selectedAbsence !== null;
    }

    get calendarHourLabels() {
        const labels = [];
        for (let h = this.calendarStartHour; h < this.calendarEndHour; h++) {
            const dt = new Date(2020, 0, 1, h, 0, 0, 0);
            labels.push(
                dt.toLocaleTimeString([], {
                    hour: 'numeric'
                })
            );
        }
        return labels;
    }

    get selectedQuickScheduleCardId() {
        if (!this.selectedAppointment) {
            return null;
        }

        return (
            this.selectedAppointment.cardId ||
            this.selectedAppointment.appointmentId ||
            null
        );
    }

    get selectedQuickScheduleExpanded() {
        const cardId = this.selectedQuickScheduleCardId;
        return cardId ? Boolean(this.quickScheduleExpanded[cardId]) : false;
    }

    get selectedQuickScheduleLabel() {
        if (!this.selectedAppointment) {
            return 'Quick schedule';
        }

        return this.getQuickScheduleToggleLabel(
            this.selectedAppointment,
            this.selectedQuickScheduleExpanded
        );
    }

    get selectedAppointmentCanQuickSchedule() {
        if (!this.selectedAppointment) {
            return false;
        }

        const canShow = this.shouldShowScheduleActions(this.selectedAppointment);

        if (this.selectedAppointment.showQuickSchedule !== undefined) {
            return (
                canShow && this.selectedAppointment.showQuickSchedule
            );
        }

        return canShow;
    }

    get selectedAppointmentScheduleBlocked() {
        return !this.hasScheduleAddress(this.selectedAppointment);
    }

    get selectedAppointmentCanEditShippingAddress() {
        if (!this.selectedAppointment) {
            return false;
        }

        const status = (
            this.selectedAppointment.workOrderStatus ||
            this.selectedAppointment.status ||
            ''
        ).toLowerCase();

        return status !== 'ready to ship';
    }

    get selectedScheduleBlockedReason() {
        return this.getAddressBlockedReason(this.selectedAppointment);
    }

    get selectedAddressHelpVisible() {
        const cardId = this.selectedQuickScheduleCardId;
        return cardId ? this.addressHelpCardId === cardId : false;
    }

    get selectedDetailQuickScheduleClass() {
        return this.selectedAppointmentScheduleBlocked
            ? 'sfs-option-button sfs-option-button_disabled'
            : 'sfs-option-button';
    }

    get selectedAppointmentQuoteLineItems() {
        if (!this.selectedAppointment) {
            return [];
        }

        return this.normalizeQuoteLineItems(
            this.selectedAppointment.quoteLineItems
        );
    }

    get selectedAppointmentHasQuoteLineItems() {
        return this.selectedAppointmentQuoteLineItems.length > 0;
    }

    get selectedAppointmentGroupedQuoteLineItems() {
        return this.groupQuoteLineItems(this.selectedAppointmentQuoteLineItems);
    }

    get isAddressFormValid() {
        return (
            this.hasCompleteAddress(this.addressForm) &&
            this.isValidStateAbbreviation(this.addressForm.state)
        );
    }

    _addressModeOptions() {
        const hasSaved = this.shippingAddressOptions.length > 0;
        return [
            { label: 'Use a saved address', value: 'saved', disabled: !hasSaved },
            { label: 'Enter an address manually', value: 'manual' }
        ];
    }

    _selectedAddressSummary(selection) {
        if (!selection) return '';
        const match = (this.shippingAddressBook || []).find(item => item.addressId === selection);
        if (!match) return '';
        return this.composeFullAddress({
            street: match.street,
            city: match.city,
            state: match.stateCode || match.state,
            postalCode: match.postalCode,
            country: match.country || match.countryCode
        });
    }

    _isAddressSelectionValid(mode, selection, isFormValid) {
        return mode === 'saved' ? Boolean(selection) : isFormValid;
    }

    get addressModeOptions() { return this._addressModeOptions(); }
    get showSavedAddressOption() { return this.addressMode === 'saved'; }
    get showManualAddressOption() { return this.addressMode === 'manual'; }
    get selectedAddressSummary() { return this._selectedAddressSummary(this.addressSelection); }
    get isAddressSelectionValid() { return this._isAddressSelectionValid(this.addressMode, this.addressSelection, this.isAddressFormValid); }
    get addressSubmitDisabled() { return this.addressSaving || !this.isAddressSelectionValid; }

    get poNumberSubmitDisabled() {
        return this.poNumberSaving;
    }

    get shippingAddressModeOptions() { return this._addressModeOptions(); }
    get showSavedShippingAddressOption() { return this.shippingAddressMode === 'saved'; }
    get showManualShippingAddressOption() { return this.shippingAddressMode === 'manual'; }
    get selectedShippingAddressSummary() { return this._selectedAddressSummary(this.shippingAddressSelection); }

    get isShippingAddressFormValid() {
        return (
            this.hasCompleteAddress(this.shippingAddressForm) &&
            this.isValidStateAbbreviation(this.shippingAddressForm.state)
        );
    }

    get isShippingAddressSelectionValid() { return this._isAddressSelectionValid(this.shippingAddressMode, this.shippingAddressSelection, this.isShippingAddressFormValid); }
    get shippingAddressSubmitDisabled() { return this.shippingAddressSaving || !this.isShippingAddressSelectionValid; }

    get repairDeclineConfirmAddressDisplay() {
        const r = this.repairDeclineConfirmRecord;
        if (!r) {
            return null;
        }
        return {
            attn: r.shippingAttn || '',
            siteName: r.shippingSiteName || '',
            street: r.shippingStreet || '',
            city: r.shippingCity || '',
            state: r.shippingState || '',
            postalCode: r.shippingPostalCode || '',
            country: r.shippingCountry || '',
            hasAttn: Boolean(r.shippingAttn),
            hasSiteName: Boolean(r.shippingSiteName),
            hasAddress: Boolean(r.hasCompleteShippingAddress)
        };
    }

    get repairDeclineConfirmAddressMissing() {
        const d = this.repairDeclineConfirmAddressDisplay;
        return !d || !d.hasAddress;
    }

    get isAccountFormValid() {
        return Boolean(this.normalizeAccountValue(this.accountForm.name));
    }

    get accountSubmitDisabled() {
        return this.accountSaving || !this.isAccountFormValid;
    }

    get isReporterContactFormValid() {
        return Boolean(this.normalizeReporterContactValue(this.reporterContactForm.info));
    }

    get reporterContactSubmitDisabled() {
        return this.reporterContactSaving || !this.isReporterContactFormValid;
    }

    get showScheduleActionsInListMode() {
        if (this.isRecentTabActive) {
            return true;
        }

        if (this.isPreventativeMaintenanceTabActive) {
            return this.isPreventativeMaintenanceUnscheduledActive;
        }

        return this.listMode !== 'readyForClose';
    }

    get isCrewMode() {
        return this.listMode === 'crew';
    }

    get isTransferMode() {
        return this.listMode === 'transferRequests';
    }

    get allowScheduleActionsOnCalendar() {
        return this.showScheduleActionsInListMode;
    }

    get showReadyForCloseAction() {
        return this.listMode === 'readyForClose';
    }

    shouldShowScheduleActions(item) {
        if (!this.showScheduleActionsInListMode) {
            return false;
        }

        if (!item) {
            return false;
        }

        return (
            !this.isReadyForCloseStatus(item) &&
            !this.isGenerateFsrStatus(item) &&
            !this.isReGenerateFsrStatus(item)
        );
    }

    get listModeOptions() {
        const probeRepairStageOptions =
            this.listOpportunityType === 'probeRepair'
                ? [
                      this.buildListModeOption(
                          'probeProposalPriceQuote',
                          'Proposal/Price Quote',
                          this.probeProposalPriceQuoteCount
                      ),
                      this.buildListModeOption(
                          'probeRepairEvaluation',
                          'Repair Evaluation',
                          this.probeRepairEvaluationCount
                      ),
                      this.buildListModeOption(
                          'probeEvaluationComplete',
                          'Evaluation Complete',
                          this.probeEvaluationCompleteCount
                      ),
                      this.buildListModeOption(
                          'probePendingApproval',
                          'Pending Approval',
                          this.probePendingApprovalCount
                      ),
                      this.buildListModeOption(
                          'probeRepairApproved',
                          'Repair Approved',
                          this.probeRepairApprovedCount
                      ),
                      this.buildListModeOption(
                          'probeExchangeApproved',
                          'Exchange Approved',
                          this.probeExchangeApprovedCount
                      ),
                      this.buildListModeOption(
                          'probeRepairDeclined',
                          'Repair Declined',
                          this.probeRepairDeclinedCount
                      )
                  ]
                : this.listOpportunityType === 'all'
                ? [
                      this.buildListModeOption(
                          'probePendingApproval',
                          'Pending Approval',
                          this.probePendingApprovalCount
                      )
                  ]
                : [];
        const options = [
            this.buildListModeOption(
                'unscheduled',
                'Unscheduled',
                this.unscheduledCount
            ),
            this.buildListModeOption('my', 'Scheduled', this.myCount),
            this.buildListModeOption('new', 'New', this.newCount),
            this.buildListModeOption(
                'pendingReceiptProbe',
                'Pending Receipt of Probe',
                this.pendingReceiptProbeCount
            ),
            ...probeRepairStageOptions,
            this.buildListModeOption(
                'transferRequests',
                'Transfer Requests',
                this.transferRequestCount
            ),
            this.buildListModeOption('crew', 'Crew Pool', this.crewCount),
            this.buildListModeOption(
                'needQuote',
                'Waiting for Operations',
                this.needQuoteCount
            ),
            this.buildListModeOption(
                'updateNeeded',
                'Update Needed',
                this.updateNeededCount
            ),
            this.buildListModeOption(
                'poRequested',
                'PO Requested',
                this.poRequestedCount
            ),
            this.buildListModeOption(
                'quoteAttached',
                'Quote Attached',
                this.quoteAttachedCount
            ),
            this.buildListModeOption(
                'quoteSent',
                'Quote Sent',
                this.quoteSentCount
            ),
            this.buildListModeOption(
                'waitingForPo',
                'Waiting for PO',
                this.waitingForPoCount
            ),
            this.buildListModeOption(
                'generateFsr',
                'Generate FSR',
                this.generateFsrCount
            ),
            this.buildListModeOption(
                'reGenerateFsr',
                'Re-Generate FSR',
                this.reGenerateFsrCount
            ),
            this.buildListModeOption(
                'readyForClose',
                'Ready for Close',
                this.readyForCloseCount
            ),
            this.buildListModeOption(
                'readyToShip',
                'Ready to Ship',
                this.readyToShipCount
            ),
            this.buildListModeOption(
                'confirmShipping',
                'Confirm Shipping',
                this.confirmShippingCount
            ),
            this.buildListModeOption(
                'pendingShipment',
                'Pending Shipment',
                this.pendingShipmentCount
            ),
            this.buildListModeOption(
                'partsProbeShipped',
                'Parts/Probe Shipped',
                this.partsProbeShippedCount
            ),
            this.buildListModeOption(
                'partsReady',
                'Parts Ready',
                this.partsReadyCount
            ),
            this.buildListModeOption(
                'fulfilling',
                'Currently Fulfilling',
                this.fulfillingCount
            ),
            this.buildListModeOption(
                'revisitPending',
                'Revisit Pending',
                this.revisitPendingCount
            )
        ];
        const optionsWithItems = options.filter(option => option.count > 0);
        if (optionsWithItems.length > 0) {
            return optionsWithItems;
        }
        return options.filter(option => option.value === 'unscheduled');
    }

    get listModeActionOptions() {
        return this.listModeOptions.filter(
            option => option.value !== 'unscheduled' && option.value !== 'my'
        );
    }

    getActionStatusModeOptions() {
        return this.listModeActionOptions.filter(option =>
            ACTION_STATUS_ALERT_MODES.has(option.value)
        );
    }

    get listModePrimaryTabs() {
        return [
            this.buildListModePrimaryTab('unscheduled', 'Unscheduled', 'unscheduled'),
            this.buildListModePrimaryTab('scheduled', 'Scheduled', 'my')
        ];
    }

    buildListModePrimaryTab(tabValue, label, baseListMode) {
        return {
            value: tabValue,
            label,
            isActive: this.listModePrimaryTab === tabValue,
            className: this.getListModePrimaryTabClass(tabValue),
            baseListMode
        };
    }

    getListModePrimaryTabClass(tabValue) {
        return this.listModePrimaryTab === tabValue
            ? 'sfs-list-mode-tabs__item sfs-list-mode-tabs__item_active'
            : 'sfs-list-mode-tabs__item';
    }

    getListModeCountForPrimaryTab(listMode, tabValue) {
        const items = this.getFilteredListModeItems(listMode);
        return this.filterListModeItemsByPrimaryTab(items, tabValue).length;
    }

    syncListModeWithOptions() {
        const options = this.listModeOptions;
        if (!options.length) {
            this.listMode = 'unscheduled';
            this.listModePrimaryTab = 'all';
            return;
        }

        if (this.listModePrimaryTab !== 'all' && this.listMode === 'my') {
            this.listModePrimaryTab = 'scheduled';
        } else if (
            this.listModePrimaryTab !== 'all' &&
            this.listMode === 'unscheduled'
        ) {
            this.listModePrimaryTab = 'unscheduled';
        }

        const tabBaseMode =
            this.listModePrimaryTab === 'scheduled'
                ? 'my'
                : this.listModePrimaryTab === 'unscheduled'
                    ? 'unscheduled'
                    : this.listMode;
        const hasItemsInTab = options.some(
            option =>
                this.getListModeCountForPrimaryTab(
                    option.value,
                    this.listModePrimaryTab
                ) > 0
        );

        if (!hasItemsInTab) {
            this.listMode = tabBaseMode;
            return;
        }

        if (
            this.getListModeCountForPrimaryTab(
                this.listMode,
                this.listModePrimaryTab
            ) === 0
        ) {
            this.listMode = tabBaseMode;
        }

        const match = options.some(option => option.value === this.listMode);
        if (!match) {
            const firstTabOption = options.find(
                option =>
                    this.getListModeCountForPrimaryTab(
                        option.value,
                        this.listModePrimaryTab
                    ) > 0
            );
            this.listMode = firstTabOption ? firstTabOption.value : tabBaseMode;
        }

        this.ensureActionStatusFocusMode();
    }

    get listModeChips() {
        const sourceOptions = this.isActionStatusFocusEnabled
            ? this.getActionStatusModeOptions()
            : this.listModeActionOptions;

        return sourceOptions
            .map(opt => ({
                ...opt,
                count: this.getListModeCountForPrimaryTab(
                    opt.value,
                    this.listModePrimaryTab
                )
            }))
            .filter(opt => opt.count > 0 || opt.value === this.listMode)
            .map(opt => ({
                value: opt.value,
                label: opt.label,
                count: opt.count,
                className: this.getListModeChipClass(opt.value, opt.count),
                countClassName: this.getListModeCountClass(
                    opt.value,
                    opt.count
                ),
                isActive: opt.value === this.listMode
            }));
    }

    get activeListModeLabel() {
        const active = this.listModeOptions.find(
            option => option.value === this.listMode
        );
        if (active) {
            return `${active.label} (${active.count})`;
        }
        const fallback = this.listModeOptions[0];
        return fallback
            ? `${fallback.label} (${fallback.count})`
            : 'Unscheduled (0)';
    }

    get activeListModeCount() {
        if (this.listMode === 'transferRequests') {
            return (
                this.transferRequestCount + this.submittedTransferRequestCount
            );
        }

        const active = this.listModeOptions.find(
            option => option.value === this.listMode
        );

        return active ? active.count : 0;
    }

    get showListSort() {
        return this.activeListModeCount > 0;
    }

    get showCalendarSort() {
        return this.hasUnscheduled;
    }

    get showPreventativeMaintenanceSort() {
        return this.hasPreventativeMaintenanceAppointments;
    }

    buildListModeOption(value, label, count) {
        return {
            value,
            label,
            count
        };
    }

    getListModeChipClass(modeValue, count) {
        let classes = 'sfs-mode-chip';

        if (modeValue === this.listMode) {
            classes += ' sfs-mode-chip_active';
        }
        if (modeValue === 'new') {
            classes += ' sfs-mode-chip_new';
        }
        if (modeValue === 'transferRequests' && count > 0) {
            classes += ' sfs-mode-chip_alert';
        }
        if (modeValue === 'crew' && this.isCrewCountUrgent) {
            classes += ' sfs-mode-chip_warning';
        }
        return classes;
    }

    getListModeCountClass(modeValue, count) {
        let classes = 'sfs-mode-chip__count';

        if (this.shouldHighlightActionStatusCount(modeValue, count)) {
            classes += ' sfs-mode-chip__count_alert';
        }

        return classes;
    }

    shouldHighlightActionStatusCount(modeValue, count) {
        return count > 0 && ACTION_STATUS_ALERT_MODES.has(modeValue);
    }

    get isTimelineMode() {
        return this.calendarMode === 'timeline';
    }

    get isWeekMode() {
        return this.calendarMode === 'week';
    }

    get timelineModeClass() {
        return this.calendarMode === 'timeline'
            ? 'sfs-mode-btn sfs-mode-btn_active'
            : 'sfs-mode-btn';
    }

    get weekModeClass() {
        return this.calendarMode === 'week'
            ? 'sfs-mode-btn sfs-mode-btn_active'
            : 'sfs-mode-btn';
    }

    // Calendar -> weeks
    get calendarWeeks() {
        const weeks = [];
        let current = [];
        let weekIndex = 0;

        this.calendarDays.forEach((day, index) => {
            current.push(day);
            if ((index + 1) % 7 === 0) {
                weeks.push({
                    key: `week-${weekIndex}`,
                    days: current
                });
                weekIndex += 1;
                current = [];
            }
        });

        if (current.length) {
            weeks.push({
                key: `week-${weekIndex}`,
                days: current
            });
        }

        return weeks;
    }

    get calendarHeaderDays() {
        const weeks = this.calendarWeeks;
        return weeks && weeks.length ? weeks[0].days : [];
    }

    get calendarRangeLabel() {
        if (!this.calendarDays || this.calendarDays.length === 0) return '';

        const first = this.calendarDays[0].date;
        const last = this.calendarDays[this.calendarDays.length - 1].date;

        const sameMonth =
            first.getMonth() === last.getMonth() &&
            first.getFullYear() === last.getFullYear();

        const optsStart = {
            month: 'short',
            day: 'numeric',
            timeZone: this.userTimeZoneId || undefined
        };
        const optsEnd = sameMonth
            ? {
                  day: 'numeric',
                  year: 'numeric',
                  timeZone: this.userTimeZoneId || undefined
              }
            : {
                  month: 'short',
                  day: 'numeric',
                  year: 'numeric',
                  timeZone: this.userTimeZoneId || undefined
              };

        return (
            first.toLocaleDateString([], optsStart) +
            ' – ' +
            last.toLocaleDateString([], optsEnd)
        );
    }

    get detailCardClass() {
        return this.isDetailClosing
            ? 'sfs-detail-card sfs-detail-card_closing'
            : 'sfs-detail-card sfs-detail-card_open';
    }

    get absenceDetailCardClass() {
        return this.isAbsenceDetailClosing
            ? 'sfs-detail-card sfs-detail-card_closing'
            : 'sfs-detail-card sfs-detail-card_open';
    }

    // Tray helpers
    get trayContainerClass() {
        const classes = ['sfs-tray'];

        if (this.pullTrayOpen) {
            classes.push('sfs-tray_open');
        }

        if (this.pullTrayPeek) {
            classes.push('sfs-tray_peek');
        }

        if (this.pullTrayOpen && (this.dragMode || this.isPressingForDrag)) {
            classes.push('sfs-tray_dragging');
        }

        return classes.join(' ');
    }

    get showTrayPeekToggle() {
        return this.pullTrayOpen && this.shouldUseCompactTray();
    }

    get trayPeekToggleLabel() {
        return this.pullTrayPeek ? 'Show more' : 'Show less';
    }

    get trayPeekHelperText() {
        return this.pullTrayPeek
            ? 'Compact view keeps the calendar visible.'
            : 'Full list is visible.';
    }

    get unscheduledCount() {
        return this.getFilteredListModeItems('unscheduled').length;
    }

    get firstTimeWorkOrders() {
        const workOrders = this.unscheduledWorkOrdersSorted;
        return workOrders.filter(wo => {
            const recordType = (wo.recordTypeName || '').toLowerCase();
            const saCount = wo.serviceAppointmentCount || 0;
            const unscheduledCount = wo.unscheduledServiceAppointmentCount || 0;

            if (recordType !== 'fsl work order') {
                return false;
            }

            if (saCount === 0) {
                return true;
            }

            return saCount === 1 && unscheduledCount === 1;
        });
    }

    get returnVisitWorkOrders() {
        const workOrders = this.unscheduledWorkOrdersSorted;
        return workOrders.filter(wo => {
            const recordType = (wo.recordTypeName || '').toLowerCase();
            const saCount = wo.serviceAppointmentCount || 0;
            const unscheduledCount = wo.unscheduledServiceAppointmentCount || 0;
            const isFirstTimeCandidate =
                saCount === 0 || (saCount === 1 && unscheduledCount === 1);

            if (recordType !== 'fsl work order' || saCount === 0) {
                return false;
            }

            if (isFirstTimeCandidate) {
                return false;
            }

            const allReturnRequired =
                wo.allServiceAppointmentsReturnRequired === true;
            const hasUnscheduledNonReturn =
                wo.hasUnscheduledNonReturnAppointment === true;

            return (allReturnRequired && unscheduledCount === 0) ||
                hasUnscheduledNonReturn;
        });
    }

    get firstTimeCount() {
        return this.firstTimeWorkOrders.length;
    }

    get returnVisitCount() {
        return this.returnVisitWorkOrders.length;
    }

    get hasUnscheduled() {
        return this.unscheduledCount > 0;
    }

    get unscheduledSortOptions() {
        return [
            {
                label: 'Account (A → Z)',
                value: 'accountAsc'
            },
            {
                label: 'Last updated (newest)',
                value: 'lastUpdatedDesc'
            },
            {
                label: 'Last updated (oldest)',
                value: 'lastUpdatedAsc'
            },
            {
                label: 'Work type (A → Z)',
                value: 'typeAsc'
            },
            {
                label: 'Status (A → Z)',
                value: 'statusAsc'
            },
            {
                label: 'Work order # (high → low)',
                value: 'workOrderNumberDesc'
            }
        ];
    }

    get preventativeMaintenanceSortOptions() {
        return [
            {
                label: 'Next service date (soonest)',
                value: 'nextServiceDateAsc'
            },
            ...this.unscheduledSortOptions
        ];
    }

    get unscheduledWorkOrdersSorted() {
        const workOrders = this.unscheduledWorkOrders || [];
        const sorted = this.sortUnscheduledWorkOrders(workOrders);
        return sorted.map(wo => this.decorateUnscheduledWorkOrder(wo));
    }

    /**
     * Friendly text for the tray handle
     * e.g. "3 work orders need scheduling" or "No work orders need scheduling"
     */
    get unscheduledLabel() {
        const count = this.unscheduledCount;

        if (count === 0) {
            return 'No work orders need scheduling';
        }
        if (count === 1) {
            return '1 work order needs scheduling';
        }
        return `${count} work orders need scheduling`;
    }

    handleUnscheduledSortChange(event) {
        this.unscheduledSortValue = event.detail.value;
    }

    handlePreventativeMaintenanceSortChange(event) {
        this.preventativeMaintenanceSortValue = event.detail.value;
    }

    getWorkOrderAccountName(workOrder) {
        if (!workOrder) {
            return '';
        }

        return workOrder.accountName || workOrder.accountNameFreeText || '';
    }

    formatUnscheduledUpdatedLabel(workOrder) {
        const lastModified = this.getLastModifiedMetadata(workOrder);
        if (!lastModified || !lastModified.date) {
            return 'Updated date unknown';
        }

        const date = new Date(lastModified.date);
        if (Number.isNaN(date.getTime())) {
            return 'Updated date unknown';
        }

        if (this.isDateToday(date)) {
            return `Updated today ${date.toLocaleTimeString([], {
                hour: 'numeric',
                minute: '2-digit'
            })}`;
        }

        return `Updated ${date.toLocaleDateString([], {
            month: 'short',
            day: 'numeric'
        })}`;
    }

    decorateUnscheduledWorkOrder(workOrder) {
        const accountDisplayName = this.getWorkOrderAccountName(workOrder);
        return {
            ...workOrder,
            accountDisplayName: accountDisplayName || 'Unassigned account',
            workTypeLabel: workOrder.workTypeName || 'Work Order',
            statusLabel: workOrder.status || 'Status unknown',
            updatedLabel: this.formatUnscheduledUpdatedLabel(workOrder),
            subjectLabel: workOrder.subject || 'Work order'
        };
    }

    getSortAccountName(item) {
        return (
            this.getWorkOrderAccountName(item) ||
            item.accountDisplayName ||
            item.accountName ||
            item.accountNameFreeText ||
            ''
        );
    }

    getSortStatusLabel(item) {
        return (
            item.workOrderStatus ||
            item.status ||
            item.statusLabel ||
            ''
        );
    }

    getSortWorkTypeName(item) {
        return item.workTypeName || item.workTypeLabel || '';
    }

    getSortWorkOrderNumber(item) {
        return item.workOrderNumber || '';
    }

    compareByDefaultSortOrder(left, right, compareResult = 0) {
        if (compareResult !== 0) {
            return compareResult;
        }

        const collator = new Intl.Collator(undefined, {
            numeric: true,
            sensitivity: 'base'
        });
        const compareText = (a, b) =>
            collator.compare((a || '').trim(), (b || '').trim());

        const workOrderNumberCompare = compareText(
            this.getSortWorkOrderNumber(left),
            this.getSortWorkOrderNumber(right)
        );
        if (workOrderNumberCompare !== 0) {
            return workOrderNumberCompare;
        }

        const accountCompare = compareText(
            this.getSortAccountName(left),
            this.getSortAccountName(right)
        );
        if (accountCompare !== 0) {
            return accountCompare;
        }

        return this.getLastModifiedTimeValue(right) -
            this.getLastModifiedTimeValue(left);
    }

    sortPreventativeMaintenanceItems(items) {
        const sortValue = this.preventativeMaintenanceSortValue;

        if (sortValue && sortValue !== 'nextServiceDateAsc') {
            return this.sortListItems(items, sortValue);
        }

        const sorted = [...items];

        sorted.sort((a, b) => {
            const aDate = this.getNextServiceDateValue(a);
            const bDate = this.getNextServiceDateValue(b);

            if (aDate && bDate) {
                if (aDate === bDate) {
                    return this.getLastModifiedTimeValue(b) -
                        this.getLastModifiedTimeValue(a);
                }
                return aDate - bDate;
            }

            if (aDate) {
                return -1;
            }

            if (bDate) {
                return 1;
            }

            return this.getLastModifiedTimeValue(b) -
                this.getLastModifiedTimeValue(a);
        });

        return sorted;
    }

    sortListItems(items, requestedSortValue = null) {
        const validSortValues = new Set(
            (this.unscheduledSortOptions || []).map(option => option.value)
        );
        const activeSortValue = requestedSortValue || this.unscheduledSortValue;
        const sortValue = validSortValues.has(activeSortValue)
            ? activeSortValue
            : 'accountAsc';
        const collator = new Intl.Collator(undefined, {
            numeric: true,
            sensitivity: 'base'
        });

        const compareText = (left, right) =>
            collator.compare((left || '').trim(), (right || '').trim());

        const sorted = [...items];

        switch (sortValue) {
            case 'lastUpdatedAsc':
                sorted.sort(
                    (a, b) =>
                        this.compareByDefaultSortOrder(
                            a,
                            b,
                            this.getLastModifiedTimeValue(a) -
                                this.getLastModifiedTimeValue(b)
                        )
                );
                break;
            case 'accountAsc':
                sorted.sort((a, b) =>
                    this.compareByDefaultSortOrder(
                        a,
                        b,
                        compareText(
                            this.getSortAccountName(a),
                            this.getSortAccountName(b)
                        )
                    )
                );
                break;
            case 'typeAsc':
                sorted.sort((a, b) =>
                    this.compareByDefaultSortOrder(
                        a,
                        b,
                        compareText(
                            this.getSortWorkTypeName(a),
                            this.getSortWorkTypeName(b)
                        )
                    )
                );
                break;
            case 'statusAsc':
                sorted.sort((a, b) =>
                    this.compareByDefaultSortOrder(
                        a,
                        b,
                        compareText(
                            this.getSortStatusLabel(a),
                            this.getSortStatusLabel(b)
                        )
                    )
                );
                break;
            case 'workOrderNumberDesc':
                sorted.sort((a, b) =>
                    this.compareByDefaultSortOrder(
                        a,
                        b,
                        compareText(
                            this.getSortWorkOrderNumber(b),
                            this.getSortWorkOrderNumber(a)
                        )
                    )
                );
                break;
            case 'lastUpdatedDesc':
            default:
                sorted.sort(
                    (a, b) =>
                        this.compareByDefaultSortOrder(
                            a,
                            b,
                            this.getLastModifiedTimeValue(b) -
                                this.getLastModifiedTimeValue(a)
                        )
                );
                break;
        }

        return sorted;
    }

    sortUnscheduledWorkOrders(workOrders) {
        return this.sortListItems(workOrders);
    }

    get pullUpTrayCriteria() {
        const criteria = [
            {
                key: 'calendarTab',
                label: 'Calendar tab is active',
                met: this.isCalendarTabActive
            },
            {
                key: 'dataLoaded',
                label: 'Data finished loading',
                met: !this.isLoading
            },
            {
                key: 'unscheduledLoaded',
                label: 'Unscheduled work orders loaded',
                met: Array.isArray(this.unscheduledWorkOrders)
            },
            {
                key: 'online',
                label: 'Online (required for scheduling)',
                met: !this.isOffline
            }
        ];

        return criteria.map(item => ({
            ...item,
            statusText: item.met ? 'Met' : 'Missing',
            statusSymbol: item.met ? '✔' : '⚠',
            itemClass: item.met
                ? 'sfs-tray-checklist__item sfs-tray-checklist__item_met'
                : 'sfs-tray-checklist__item sfs-tray-checklist__item_missing'
        }));
    }

    get isTrayReady() {
        return this.pullUpTrayCriteria.every(item => item.met);
    }

    get trayReadinessSummary() {
        return this.isTrayReady
            ? 'All criteria are satisfied. The pull-up bar should appear below.'
            : 'One or more criteria are missing. Resolve the items below to render the pull-up bar.';
    }

    get trayStatusClass() {
        return this.isTrayReady
            ? 'sfs-tray-debug__badge sfs-tray-debug__badge_ready'
            : 'sfs-tray-debug__badge sfs-tray-debug__badge_blocked';
    }

    get trayStatusLabel() {
        return this.isTrayReady ? 'Ready' : 'Blocked';
    }

    get shouldRenderTray() {
        return this.isTrayReady;
    }

    updateActiveTabState(explicitValue, options = {}) {
        const { suppressCalendarToday = false } = options;
        let resolvedTabValue = explicitValue;

        if (resolvedTabValue === undefined || resolvedTabValue === null) {
            resolvedTabValue =
                this.activeTab ||
                this.lastKnownActiveTab ||
                'list';
        }

        if (resolvedTabValue === 'manager' && !this.isManager) {
            resolvedTabValue = 'list';
        }

        if (resolvedTabValue) {
            this.activeTab = resolvedTabValue;
            this.lastKnownActiveTab = resolvedTabValue;
        }

        const isCalendarActive = resolvedTabValue === 'calendar';
        const wasCalendarActive = this.isCalendarTabActive;

        if (isCalendarActive !== this.isCalendarTabActive) {
            this.isCalendarTabActive = isCalendarActive;

            if (!isCalendarActive) {
                this.pullTrayOpen = false;
            } else if (!wasCalendarActive && !suppressCalendarToday) {
                // Ensure the calendar recenters on today whenever the user
                // switches into the calendar tab (keyboard, click, or
                // programmatic activation).
                this.handleCalendarToday();
            }
        }

        if (isCalendarActive) {
            this.ensureCalendarModelForActiveTab();
        }
    }

    // ======= LIFECYCLE =======

    connectedCallback() {
        try {
            this.registerGlobalErrorHandlers();
            this.checkOnline();
            this.handleCalendarToday();
            if (!this.isOffline) {
                this.loadAppointments({ dataScope: this.getDataScopeForTab(this.activeTab) });
            }
        } catch (error) {
            this.captureError(error, 'connectedCallback');
        }
    }

    disconnectedCallback() {
        this.safeClearTimeout(this._historySearchDebounceTimeout);
        this._historySearchDebounceTimeout = null;
        clearTimeout(this._addressInputDebounceTimer);
        clearTimeout(this._shippingAddressInputDebounceTimer);
        clearTimeout(this._poNumberModalDebounceTimer);
        clearTimeout(this._poNumberInlineDebounceTimer);
        this.unregisterGlobalErrorHandlers();
        if (this._listSentinelObserver) {
            this._listSentinelObserver.disconnect();
            this._listSentinelObserver = null;
        }
    }

    renderedCallback() {
        try {
            this.updateActiveTabState();

            if (
                this.isTimelineMode &&
                this.isCalendarTabActive &&
                this._needsCenterOnToday &&
                this.calendarDays &&
                this.calendarDays.length > 0
            ) {
                this.centerTimelineOnTodayColumn();
            }

            this.scheduleNowLinePositionUpdate();
            this._setupListSentinel();
        } catch (error) {
            this.captureError(error, 'renderedCallback');
        }
    }

    _setupListSentinel() {
        const sentinel = this.template.querySelector('.sfs-list-sentinel');
        if (!sentinel) {
            if (this._listSentinelObserver) {
                this._listSentinelObserver.disconnect();
                this._listSentinelObserver = null;
                this._listSentinelObservedEl = null;
            }
            return;
        }
        if (this._listSentinelObservedEl === sentinel) {
            return;
        }
        if (this._listSentinelObserver) {
            this._listSentinelObserver.disconnect();
        }
        this._listSentinelObservedEl = sentinel;
        this._listSentinelObserver = new IntersectionObserver(
            (entries) => {
                if (entries[0].isIntersecting) {
                    this.listVisibleCount += 10;
                }
            },
            { threshold: 0.1 }
        );
        this._listSentinelObserver.observe(sentinel);
    }

    resetListPagination() {
        this.listVisibleCount = 10;
    }

    errorCallback(error, stack) {
        this.captureError(error, 'errorCallback');

        if (!stack) {
            return;
        }

        const currentLastError = (this.debugInfo && this.debugInfo.lastError) || {};

        this.debugInfo = Object.assign({}, this.debugInfo, {
            lastError: Object.assign({}, currentLastError, {
                stack: stack
            })
        });
        const lastError = (this.debugInfo && this.debugInfo.lastError) || {};

        this.debugInfo = Object.assign({}, this.debugInfo, {
            lastError: Object.assign({}, lastError, {
                stack: stack
            })
        });
        lastError = this.debugInfo?.lastError || {};

        this.debugInfo = {
            ...this.debugInfo,
            lastError: {
                ...lastError,
                stack
            }
        };
    }

    // ======= ONLINE CHECK =======

    checkOnline() {
        if (typeof navigator !== 'undefined' && navigator.onLine === false) {
            this.isOffline = true;
        } else {
            this.isOffline = false;
        }
    }

    // ======= CALENDAR RANGE CONTROL =======

    centerCalendarOnToday(shouldBuild = true) {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const timelineStart = new Date(today);
        timelineStart.setDate(today.getDate() - 7);
        this.timelineStartDate = timelineStart;

        const dow = today.getDay();
        const weekStart = new Date(today);
        weekStart.setDate(today.getDate() - dow);
        this.weekStartDate = weekStart;

        this.hasAutoCentered = false;
        if (shouldBuild) {
            this.buildCalendarModel();
        }
    }

    centerTimelineOnTodayColumn() {
        const wrapper = this.template.querySelector(
            '.sfs-calendar-days-wrapper'
        );
        const todayCol = this.template.querySelector(
            '.sfs-calendar-day_today'
        );
        const daysContainer = this.template.querySelector(
            '.sfs-calendar-days'
        );

        if (!wrapper || !daysContainer || !todayCol) {
            this._needsCenterOnToday = false;
            return;
        }

        const wrapperWidth = wrapper.clientWidth;
        const todayCenter =
            todayCol.offsetLeft + todayCol.offsetWidth / 2;

        const targetScrollLeft = Math.max(
            0,
            todayCenter - wrapperWidth / 2
        );

        wrapper.scrollLeft = targetScrollLeft;
        this.centerTimelineOnElevenAmLine(todayCol);
        this._needsCenterOnToday = false;
    }

    centerTimelineOnElevenAmLine(todayCol) {
        if (typeof window === 'undefined') {
            return;
        }

        const dayBody =
            todayCol?.querySelector('.sfs-calendar-day-body') ||
            this.template.querySelector('.sfs-calendar-day-body');

        if (!dayBody) {
            return;
        }

        const bodyRect = dayBody.getBoundingClientRect();
        const elevenAmOffset = (11 / 24) * bodyRect.height;
        const targetScrollTop =
            bodyRect.top + window.scrollY + elevenAmOffset - window.innerHeight / 2;

        window.scrollTo({
            top: Math.max(targetScrollTop, 0)
        });
    }

    shiftCalendar(offsetDays) {
        if (!this.timelineStartDate && !this.weekStartDate) {
            this.centerCalendarOnToday();
            return;
        }

        if (this.isTimelineMode) {
            const start = new Date(this.timelineStartDate || new Date());
            start.setDate(start.getDate() + offsetDays);
            this.timelineStartDate = start;
        } else {
            const start = new Date(this.weekStartDate || new Date());
            start.setDate(start.getDate() + offsetDays);
            this.weekStartDate = start;
        }

        this.hasAutoCentered = false;
        this.buildCalendarModel();
    }

    getClientPoint(event) {
        if (!event) {
            return null;
        }

        const touch =
            (event.touches && event.touches[0]) ||
            (event.changedTouches && event.changedTouches[0]);

        if (touch) {
            return { clientX: touch.clientX, clientY: touch.clientY };
        }

        if (
            typeof event.clientX === 'number' &&
            typeof event.clientY === 'number'
        ) {
            return { clientX: event.clientX, clientY: event.clientY };
        }

        return null;
    }

    // ======= DRAG HANDLERS (events) =======

    handleEventDragStart(event) {
        // Allow action buttons inside an event (e.g., remove/unschedule) to work on touch
        // devices without being intercepted by drag handlers.
        if (event.target && event.target.closest('.sfs-unassign-btn')) {
            return;
        }

        if (event.target && event.target.closest('.sfs-calendar-event-resize')) {
            return;
        }

        if (this.isCalendarPanMode) {
            return;
        }

        // Do not start another drag if one is already running
        if (this.dragMode || this.isPressingForDrag) {
            return;
        }

        if (event.currentTarget.dataset.kind === 'absence') {
            return;
        }

        const id = event.currentTarget.dataset.id;
        const dayIndexStr = event.currentTarget.dataset.dayIndex;
        if (!id || dayIndexStr === undefined) {
            return;
        }

        const appt = this.appointments.find(a => a.appointmentId === id);
        if (!appt || !appt.schedStart) {
            return;
        }

        const clientPoint = this.getClientPoint(event);
        if (!clientPoint) {
            return;
        }

        const dayIndex = parseInt(dayIndexStr, 10);

        const localStart = this.convertUtcToUserLocal(appt.schedStart);

        const dayBodyEl = event.currentTarget.closest('.sfs-calendar-day-body');
        const dayEl = event.currentTarget.closest('.sfs-calendar-day');

        if (!dayBodyEl || !dayEl) {
            return;
        }

        const bodyRect = dayBodyEl.getBoundingClientRect();

        const pending = {
            type: 'event',
            id,
            dayIndex,
            localStart,
            clientX: clientPoint.clientX,
            clientY: clientPoint.clientY,
            dayBodyHeight: bodyRect.height || dayBodyEl.clientHeight || 1,
            dayBodyTop: bodyRect.top,
            dayWidth: dayEl.clientWidth || 1,
            title: this.getServiceAppointmentDisplayTitle(appt)
        };


        this.isPressingForDrag = true;
        this._pendingDrag = pending;

        // Long press threshold: require a deliberate press-and-hold to move
        this.clearLongPressTimer();
        this.dragLongPressTimer = this.safeSetTimeout(() => {
            this.beginDragFromPending();
        }, this.dragHoldDelayMs);

        // On touch devices, allow the synthetic click event to fire so a quick tap
        // opens the info drawer. Prevent default only for mouse/pen interactions to
        // avoid suppressing the click on mobile while still stopping accidental
        // text selection when dragging with a mouse.
        const isTouchStart = event.type === 'touchstart';
        if (!isTouchStart) {
            event.preventDefault();
            event.stopPropagation();
        }
    }

    handleEventPressEnd() {
        // If we were only waiting for a long press and never started a drag, cancel it
        if (this.isPressingForDrag && !this.dragMode) {
            this.isPressingForDrag = false;
            this._pendingDrag = null;
            this.clearLongPressTimer();
        }
    }

    handleEventResizeStart(event) {
        if (!event) {
            return;
        }

        if (this.isCalendarPanMode) {
            return;
        }

        if (this.dragMode || this.isPressingForDrag) {
            return;
        }

        if (event.currentTarget.dataset.kind === 'absence') {
            return;
        }

        const id = event.currentTarget.dataset.id;
        const dayIndexStr = event.currentTarget.dataset.dayIndex;
        if (!id || !dayIndexStr) {
            return;
        }

        const dayIndex = parseInt(dayIndexStr, 10);
        const appt = this.appointments.find(a => a.appointmentId === id);
        if (!appt || !appt.schedStart) {
            return;
        }

        const clientPoint = this.getClientPoint(event);
        if (!clientPoint) {
            return;
        }

        const dayBodyEl = event.currentTarget.closest('.sfs-calendar-day-body');
        const dayEl = event.currentTarget.closest('.sfs-calendar-day');
        const eventEl = event.currentTarget.closest('.sfs-calendar-event');

        if (!dayBodyEl || !dayEl || !eventEl) {
            return;
        }

        const startLocal = this.convertUtcToUserLocal(appt.schedStart);
        const endLocal = appt.schedEnd
            ? this.convertUtcToUserLocal(appt.schedEnd)
            : new Date(startLocal.getTime() + 60 * 60 * 1000);

        const pending = {
            type: 'resize',
            id,
            dayIndex,
            localStart: startLocal,
            localEnd: endLocal,
            clientX: clientPoint.clientX,
            clientY: clientPoint.clientY
        };

        this.isPressingForDrag = false;
        this._pendingDrag = pending;
        this.clearLongPressTimer();
        this.beginDragFromPending();

        event.preventDefault();
        event.stopPropagation();
    }



    // ======= DRAG HANDLERS (tray -> calendar) =======
    handleTrayCardDragStart(event) {
        if (this.dragMode || this.isPressingForDrag) {
            return;
        }

        if (!event || !event.currentTarget) {
            this.resetDragState();
            return;
        }

        const card = event.currentTarget;
        const workOrderId = card.dataset && card.dataset.woid;
        if (!workOrderId) {
            return;
        }

        const addressSource = (this.unscheduledWorkOrders || []).find(
            wo => wo.workOrderId === workOrderId
        );

        if (!this.hasScheduleAddress(addressSource)) {
            const cardId = addressSource ? addressSource.cardId : workOrderId;
            this.showAddressRequiredHelp(cardId);
            return;
        }

        const clientPoint = this.getClientPoint(event);
        if (!clientPoint) {
            return;
        }

        // Use first day column/body to measure width and height
        const dayEl = this.template.querySelector('.sfs-calendar-day');
        const dayBodyEl = this.template.querySelector('.sfs-calendar-day-body');

        if (!dayEl || !dayBodyEl) {
            return;
        }

        if (this.pullTrayOpen && this.shouldUseCompactTray()) {
            this._trayWasExpandedBeforeDrag = !this.pullTrayPeek;
            this.pullTrayPeek = true;
        }

        const startIndex =
            this.todayDayIndex != null ? this.todayDayIndex : 0;

        const bodyRect = dayBodyEl.getBoundingClientRect();

        const pending = {
            type: 'wo',
            workOrderId,
            dayIndex: startIndex,
            clientX: clientPoint.clientX,
            clientY: clientPoint.clientY,
            dayBodyHeight: bodyRect.height || dayBodyEl.clientHeight || 1,
            dayBodyTop: bodyRect.top,
            dayWidth: dayEl.clientWidth || 1,
            title: card.querySelector('.sfs-tray-card-title')
                ? card.querySelector('.sfs-tray-card-title').textContent
                : 'New appointment'
        };

        this.isPressingForDrag = true;
        this._pendingDrag = pending;

        this.clearLongPressTimer();
        this.dragLongPressTimer = this.safeSetTimeout(() => {
            this.beginDragFromPending();
        }, this.dragHoldDelayMs);

        event.preventDefault();
        event.stopPropagation();
    }

    clearLongPressTimer() {
        if (this.dragLongPressTimer) {
            this.safeClearTimeout(this.dragLongPressTimer);
            this.dragLongPressTimer = null;
        }
    }

    compactTrayForDrag() {
        if (!this.pullTrayOpen) {
            this._trayOpenBeforeDrag = false;
            return;
        }

        this._trayOpenBeforeDrag = true;

        if (this.shouldUseCompactTray()) {
            if (!this.pullTrayPeek) {
                this._trayWasExpandedBeforeDrag = true;
            }
            this.pullTrayPeek = true;
        } else {
            this._trayWasExpandedBeforeDrag = true;
            this.pullTrayOpen = false;
        }
    }

    beginDragFromPending() {
        const pending = this._pendingDrag;
        this.isPressingForDrag = false;
        this._pendingDrag = null;
        this.clearLongPressTimer();

        // Always use the explicit confirmation UI (✓ / ✕) for scheduling or
        // rescheduling drags. Resizing should apply immediately without the
        // confirmation flow.
        this.dragRequiresExplicitConfirmation = pending.type !== 'resize';

        if (!pending) {
            return;
        }

        if (pending.type === 'event') {
            this.dragMode = 'event';
            this.draggingEventId = pending.id;
            this.draggingWorkOrderId = null;
            this.dragDayBodyTop = pending.dayBodyTop;
            this.dragStartDayIndex = pending.dayIndex;
            this.dragCurrentDayIndex = pending.dayIndex;
            this.dragStartLocal = pending.localStart;
            this.dragStartEndLocal = null;
            this.dragStartClientX = pending.clientX;
            this.dragStartClientY = pending.clientY;
            this.dragDayBodyHeight = pending.dayBodyHeight;
            this.dragDayWidth = pending.dayWidth;
            this.dragHasMoved = false;
            this.dragPreviewLocal = null;
            this.dragPreviewDurationHours = null;
            this.dragDurationHours = null;

            // Find the original event DOM node to clone its size
            const selector = `.sfs-calendar-day-body [data-id="${pending.id}"][data-day-index="${pending.dayIndex}"]`;
            const evtEl = this.template.querySelector(selector);
            let width = 120;
            let height = 40;

            if (evtEl) {
                const rect = evtEl.getBoundingClientRect();
                width = rect.width;
                height = rect.height;

                const offsetWithinEvent = pending.clientY - rect.top;
                this.dragGhostPointerOffsetY = Math.min(
                    Math.max(offsetWithinEvent, 0),
                    height
                );
            } else {
                this.dragGhostPointerOffsetY = height / 2;
            }

            // Work out the type class for coloring
            const appt = this.appointments.find(a => a.appointmentId === pending.id);
            const typeClass = appt
                ? this.getEventTypeClass(appt.workTypeName)
                : '';

            if (appt) {
                const endLocal = appt.schedEnd
                    ? this.convertUtcToUserLocal(appt.schedEnd)
                    : new Date(
                          pending.localStart.getTime() + 60 * 60 * 1000
                      );

                this.dragStartEndLocal = endLocal;

                const durationHours = this.computeDurationHours(
                    pending.localStart,
                    endLocal
                );
                this.dragDurationHours = durationHours;
                this.dragPreviewDurationHours = durationHours;

                const totalHours = this.calendarEndHour - this.calendarStartHour;
                const scaledHeight =
                    (durationHours / totalHours) * this.dragDayBodyHeight;
                height = scaledHeight;

                const timeLabel = this.formatTimeRange(
                    pending.localStart,
                    endLocal
                );

                const { offsetWithinGhost, ghostHeight } =
                    this.computeGhostPointerOffsetFromCalendar(
                        pending.dayIndex,
                        pending.localStart,
                        durationHours,
                        pending.clientY,
                        height,
                        this.dragGhostPointerOffsetY
                    );

                this.dragGhostPointerOffsetY = offsetWithinGhost;
                const finalHeight = ghostHeight || height;

                this.showDragGhost(
                    pending.clientX,
                    pending.clientY - this.dragGhostPointerOffsetY,
                    pending.title,
                    timeLabel,
                    typeClass,
                    width,
                    finalHeight
                );

                this.compactTrayForDrag();

                this.updateSelectedEventStyles();
                this.showTrayCancelZone = false;
                this.registerGlobalDragListeners();
                return;
            }

            const timeLabel = pending.localStart.toLocaleTimeString([], {
                hour: 'numeric',
                minute: '2-digit'
            });

            this.dragGhostPointerOffsetY = height / 2;

            this.showDragGhost(
                pending.clientX,
                pending.clientY - this.dragGhostPointerOffsetY,
                pending.title,
                timeLabel,
                typeClass,
                width,
                height
            );

            this.compactTrayForDrag();

            this.updateSelectedEventStyles();
        } else if (pending.type === 'resize') {
            this.dragMode = 'resize';
            this.draggingEventId = pending.id;
            this.draggingWorkOrderId = null;
            this.dragStartDayIndex = pending.dayIndex;
            this.dragCurrentDayIndex = pending.dayIndex;
            this.dragStartLocal = pending.localStart;
            this.dragStartEndLocal = pending.localEnd;
            this.dragStartClientX = pending.clientX;
            this.dragStartClientY = pending.clientY;
            this.dragHasMoved = false;
            this.dragPreviewLocal = new Date(pending.localStart);

            const appt = this.appointments.find(
                a => a.appointmentId === pending.id
            );
            const dayBodyEl = this.template.querySelector(
                `.sfs-calendar-day[data-day-index="${pending.dayIndex}"] .sfs-calendar-day-body`
            );
            const dayEl = this.template.querySelector(
                `.sfs-calendar-day[data-day-index="${pending.dayIndex}"]`
            );
            const eventEl = this.template.querySelector(
                `.sfs-calendar-day-body [data-id="${pending.id}"][data-day-index="${pending.dayIndex}"]`
            );

            if (!dayBodyEl || !dayEl || !eventEl || !appt) {
                this.resetDragState();
                return;
            }

            const bodyRect = dayBodyEl.getBoundingClientRect();
            const dayRect = dayEl.getBoundingClientRect();
            const eventRect = eventEl.getBoundingClientRect();

            const durationHours = this.computeDurationHours(
                pending.localStart,
                pending.localEnd
            );

            this.dragDurationHours = durationHours;
            this.dragPreviewDurationHours = durationHours;
            this.dragDayBodyHeight = bodyRect.height || dayBodyEl.clientHeight || 1;
            this.dragDayBodyTop = bodyRect.top;
            this.dragDayWidth = dayRect.width || 1;

            const totalHours = this.calendarEndHour - this.calendarStartHour;
            const startHourFraction =
                pending.localStart.getHours() +
                pending.localStart.getMinutes() / 60;
            const yWithinBody =
                ((startHourFraction - this.calendarStartHour) / totalHours) *
                this.dragDayBodyHeight;

            const ghostHeight =
                (durationHours / totalHours) * this.dragDayBodyHeight;
            const ghostX = dayRect.left + dayRect.width / 2;
            const timeLabel = this.formatTimeRange(
                pending.localStart,
                pending.localEnd
            );
            const typeClass = this.getEventTypeClass(appt.workTypeName);

            this.dragGhostPointerOffsetY = 0;

            this.showDragGhost(
                ghostX,
                this.dragDayBodyTop + yWithinBody,
                this.getServiceAppointmentDisplayTitle(appt),
                timeLabel,
                typeClass,
                eventRect.width,
                ghostHeight
            );

            this.updateSelectedEventStyles();
            this.showTrayCancelZone = false;
            this.registerGlobalDragListeners();
            return;
        } else if (pending.type === 'wo') {
            this.dragMode = 'wo';
            this.draggingWorkOrderId = pending.workOrderId;
            this.draggingEventId = null;
            this.dragStartDayIndex = pending.dayIndex;
            this.dragCurrentDayIndex = pending.dayIndex;
            this.dragStartLocal = null;
            this.dragStartEndLocal = null;
            this.dragStartClientX = pending.clientX;
            this.dragStartClientY = pending.clientY;
            this.dragDayBodyHeight = pending.dayBodyHeight;
            this.dragDayWidth = pending.dayWidth;
            this.dragHasMoved = false;
            this.dragDayBodyTop = pending.dayBodyTop;
            this.dragPreviewLocal = null;
            this.dragPreviewDurationHours = this.defaultWorkOrderDurationHours;
            this.dragDurationHours = this.defaultWorkOrderDurationHours;


            // Approximate size for a new 6-hour event
            const dayHeight = pending.dayBodyHeight;
            const sixHourHeight =
                (this.defaultWorkOrderDurationHours / 24) * dayHeight;
            const width = pending.dayWidth * 0.88; // match left/right 6% padding
            const height = sixHourHeight;

            this.dragGhostPointerOffsetY = height / 2;

            const dayObj = this.calendarDays[pending.dayIndex];
            const preview = new Date(dayObj.date);
            preview.setHours(9, 0, 0, 0);

            const endPreview = new Date(preview);
            endPreview.setHours(
                endPreview.getHours() + this.defaultWorkOrderDurationHours,
                endPreview.getMinutes(),
                0,
                0
            );

            const timeLabel = this.formatTimeRange(preview, endPreview);

            const { offsetWithinGhost, ghostHeight } =
                this.computeGhostPointerOffsetFromCalendar(
                    pending.dayIndex,
                    preview,
                    this.defaultWorkOrderDurationHours,
                    pending.clientY,
                    height,
                    this.dragGhostPointerOffsetY
                );

            this.dragGhostPointerOffsetY = offsetWithinGhost;
            const finalHeight = ghostHeight || height;

            this.showDragGhost(
                pending.clientX,
                pending.clientY - this.dragGhostPointerOffsetY,
                pending.title,
                timeLabel,
                'sfs-event-default',
                width,
                finalHeight
            );
        }

        this.compactTrayForDrag();
        this.showTrayCancelZone = pending.type === 'wo';
        this.registerGlobalDragListeners();



    }

    showDragGhost(
        x,
        y,
        title,
        timeLabel,
        typeClass,
        width,
        height,
        anchoredToCalendar = false
    ) {
        this.dragGhostVisible = true;
        this.dragGhostX = x;
        this.dragGhostY = y;
        this.dragGhostAnchoredToCalendar = anchoredToCalendar;
        this.dragGhostTitle = title || '';
        this.dragGhostTime = timeLabel || '';
        this.dragGhostTypeClass = typeClass || '';
        this.dragGhostWidth = width || 120;
        this.dragGhostHeight = height || 40;
    }

    hideDragGhost() {
        this.dragGhostVisible = false;
        this.dragGhostAnchoredToCalendar = false;
        this.dragGhostTitle = '';
        this.dragGhostTime = '';
        this.dragGhostTypeClass = '';
        this.dragGhostWidth = 0;
        this.dragGhostHeight = 0;
    }


    getDayIndexFromClientX(clientX) {
        const dayEls = Array.from(
            this.template.querySelectorAll('.sfs-calendar-day')
        );

        if (!dayEls.length) {
            return null;
        }

        let bestIndex = null;
        let bestDistance = Infinity;

        dayEls.forEach(el => {
            const idxStr = el.dataset.dayIndex;
            if (idxStr === undefined) {
                return;
            }

            const rect = el.getBoundingClientRect();
            const center = rect.left + rect.width / 2;

            if (clientX >= rect.left && clientX <= rect.right) {
                bestIndex = parseInt(idxStr, 10);
                bestDistance = 0;
                this.dragDayWidth = rect.width || this.dragDayWidth;
                return;
            }

            const distance = Math.abs(clientX - center);
            if (distance < bestDistance) {
                bestDistance = distance;
                bestIndex = parseInt(idxStr, 10);
                this.dragDayWidth = rect.width || this.dragDayWidth;
            }
        });

        return bestIndex;
    }


    stopAutoScrollLoop() {
        if (this._autoScrollFrame) {
            cancelAnimationFrame(this._autoScrollFrame);
            this._autoScrollFrame = null;
        }

        this._autoScrollPoint = null;
    }

    updateAutoScroll(clientX, clientY) {
        this._autoScrollPoint = { clientX, clientY };

        if (!this._autoScrollFrame) {
            this._autoScrollFrame = requestAnimationFrame(() =>
                this.performAutoScroll()
            );
        }
    }

    performAutoScroll() {
        this._autoScrollFrame = null;

        if (!this.dragMode || !this._autoScrollPoint) {
            return;
        }

        const { clientX, clientY } = this._autoScrollPoint;
        const edgeThreshold = 80;
        const maxStep = 18;
        const viewportWidth = window.innerWidth || 0;
        const viewportHeight = window.innerHeight || 0;

        const computeStep = distance => {
            const overlap = Math.max(edgeThreshold - distance, 0);
            if (!overlap) {
                return 0;
            }
            return Math.round((overlap / edgeThreshold) * maxStep);
        };

        let deltaX = 0;
        let deltaY = 0;

        const leftDistance = clientX;
        const rightDistance = viewportWidth - clientX;
        const topDistance = clientY;
        const bottomDistance = viewportHeight - clientY;

        deltaX -= computeStep(leftDistance);
        deltaX += computeStep(rightDistance);
        deltaY -= computeStep(topDistance);
        deltaY += computeStep(bottomDistance);

        const wrapper = this.template.querySelector('.sfs-calendar-days-wrapper');
        if (wrapper && deltaX !== 0) {
            wrapper.scrollLeft += deltaX;
        }

        if (deltaY !== 0) {
            window.scrollBy({ top: deltaY, behavior: 'auto' });
        }

        if (deltaX !== 0 || deltaY !== 0) {
            this._autoScrollFrame = requestAnimationFrame(() =>
                this.performAutoScroll()
            );
        }
    }




    handleCalendarPointerMove(event) {
        if (this.isCalendarPanMode) {
            return;
        }

        if (!this.dragMode || this.dragStartClientX === null) {
            return;
        }

        const clientPoint = this.getClientPoint(event);
        if (!clientPoint) {
            return;
        }
        const { clientX, clientY } = clientPoint;

        this.updateAutoScroll(clientX, clientY);
        this.updateTrayCancelHover(clientX, clientY);

        const dx = clientX - this.dragStartClientX;
        const dy = clientY - this.dragStartClientY;

        if (!this.dragHasMoved && (Math.abs(dx) > 5 || Math.abs(dy) > 5)) {
            this.dragHasMoved = true;
        }

        let newDayIndex = this.getDayIndexFromClientX(clientX);
        if (this.dragMode === 'resize') {
            newDayIndex = this.dragStartDayIndex;
        } else if (newDayIndex == null) {
            const dayOffset = Math.round(dx / this.dragDayWidth);
            newDayIndex = this.dragStartDayIndex + dayOffset;
        }
        if (newDayIndex < 0) newDayIndex = 0;
        if (newDayIndex >= this.calendarDays.length) {
            newDayIndex = this.calendarDays.length - 1;
        }
        this.dragCurrentDayIndex = newDayIndex;

        const bodyHeightForDelta = this.dragDayBodyHeight || 1;
        let hoursDelta = (dy / bodyHeightForDelta) * 24;

        // When resizing, snap duration changes to 15-minute increments
        if (this.dragMode === 'resize') {
            hoursDelta = Math.round(hoursDelta / 0.25) * 0.25;
        }

        // Compute preview local time for the ghost
        let previewLocal;
        const dayObj = this.calendarDays[newDayIndex];
        const baseDay = new Date(dayObj.date);

        const dayEl = this.template.querySelector(
            `.sfs-calendar-day[data-day-index="${newDayIndex}"]`
        );
        const dayBodyEl = dayEl
            ? dayEl.querySelector('.sfs-calendar-day-body')
            : null;
        const bodyRect = dayBodyEl
            ? dayBodyEl.getBoundingClientRect()
            : null;

        if (bodyRect) {
            this.dragDayBodyHeight = bodyRect.height || this.dragDayBodyHeight;
            this.dragDayBodyTop = bodyRect.top;
        }

        if (this.dragMode === 'event' && this.dragStartLocal) {
            previewLocal = new Date(baseDay);
            previewLocal.setHours(
                this.dragStartLocal.getHours(),
                this.dragStartLocal.getMinutes(),
                0,
                0
            );

            const millisDelta = hoursDelta * 60 * 60 * 1000;
            previewLocal.setTime(previewLocal.getTime() + millisDelta);
        } else if (this.dragMode === 'resize' && this.dragStartLocal) {
            previewLocal = new Date(baseDay);
            previewLocal.setHours(
                this.dragStartLocal.getHours(),
                this.dragStartLocal.getMinutes(),
                0,
                0
            );
        } else if (this.dragMode === 'wo') {
            previewLocal = new Date(baseDay);
            const usableHeight = this.dragDayBodyHeight || 1;
            const pointerYWithinBody =
                clientY -
                (this.dragDayBodyTop != null ? this.dragDayBodyTop : 0) -
                (this.dragGhostPointerOffsetY || 0);
            const relativeY = Math.max(
                0,
                Math.min(usableHeight, pointerYWithinBody)
            );
            const totalHours = this.calendarEndHour - this.calendarStartHour;
            const hourFraction =
                this.calendarStartHour + (relativeY / usableHeight) * totalHours;
            const hours = Math.floor(hourFraction);
            const minutes = Math.round((hourFraction - hours) * 60);
            previewLocal.setHours(hours, minutes, 0, 0);
        }

        if (previewLocal) {
            const minutes = previewLocal.getMinutes();
            const roundedMinutes = Math.round(minutes / 15) * 15;
            previewLocal.setMinutes(roundedMinutes, 0, 0);

            this.dragPreviewLocal = new Date(previewLocal);

        }

        const totalHours = this.calendarEndHour - this.calendarStartHour;

        if (previewLocal && this.dragDayBodyTop != null) {
            let durationHours = this.dragDurationHours || 1;

            if (this.dragMode === 'resize' && this.dragStartEndLocal) {
                const baseDuration = this.computeDurationHours(
                    this.dragStartLocal,
                    this.dragStartEndLocal
                );
                durationHours = baseDuration + hoursDelta;
                const startHourFraction =
                    previewLocal.getHours() + previewLocal.getMinutes() / 60;
                const maxDuration =
                    this.calendarEndHour - startHourFraction;
                durationHours = Math.min(
                    Math.max(durationHours, 0.25),
                    Math.max(maxDuration, 0.25)
                );
                this.dragPreviewDurationHours = durationHours;
            } else {
                this.dragPreviewDurationHours = durationHours;
            }

            const endPreview = new Date(previewLocal);
            endPreview.setTime(
                endPreview.getTime() + durationHours * 60 * 60 * 1000
            );

            const timeLabel = this.formatTimeRange(previewLocal, endPreview);

            // Convert previewLocal time -> vertical position in day body
            let hourFraction =
                previewLocal.getHours() + previewLocal.getMinutes() / 60;

            // Clamp within visible calendar hours
            if (hourFraction < this.calendarStartHour) {
                hourFraction = this.calendarStartHour;
            }
            if (hourFraction > this.calendarEndHour) {
                hourFraction = this.calendarEndHour;
            }

            const bodyHeight = this.dragDayBodyHeight || 1;
            const topRatio =
                (hourFraction - this.calendarStartHour) / totalHours;
            const yWithinBody = topRatio * bodyHeight;

            const ghostHeight = (durationHours / totalHours) * bodyHeight;

            // Position ghost horizontally at the center of the target day column
            let ghostX = clientX;
            const dayElForGhost = this.template.querySelector(
                `.sfs-calendar-day[data-day-index="${newDayIndex}"]`
            );
            if (dayElForGhost) {
                const dayRect = dayElForGhost.getBoundingClientRect();
                ghostX = dayRect.left + dayRect.width / 2;
                // Keep day width in sync
                this.dragDayWidth = dayRect.width;
            }

            // Anchor the ghost to the pointer using the recorded grab offset so
            // grabbing anywhere on the card (top, middle, or bottom) keeps the
            // start time aligned with the calendar slot while dragging.
            let ghostY =
                clientY - (this.dragGhostPointerOffsetY || 0);
            if (
                this.dragMode === 'resize' &&
                this.dragDayBodyTop != null
            ) {
                ghostY = this.dragDayBodyTop + yWithinBody;
            }

            this.showDragGhost(
                ghostX,
                ghostY,
                this.dragGhostTitle,
                timeLabel,
                this.dragGhostTypeClass,
                this.dragGhostWidth,
                ghostHeight || this.dragGhostHeight
            );
        } else {
            // Fallback – just move with finger if we somehow lack geometry
            this.showDragGhost(
                clientX,
                clientY - (this.dragGhostPointerOffsetY || 0),
                this.dragGhostTitle,
                this.dragGhostTime,
                this.dragGhostTypeClass,
                this.dragGhostWidth,
                this.dragGhostHeight
            );
        }
        event.preventDefault();
    }


    handleCalendarPointerEnd(event) {
        if (this.isCalendarPanMode) {
            this.resetDragState();
            return;
        }

        if (!this.dragMode || this.dragStartClientX === null) {
            this.resetDragState();
            return;
        }

        const clientPoint = this.getClientPoint(event);
        if (!clientPoint) {
            this.resetDragState();
            return;
        }

        const { clientX, clientY } = clientPoint;

        const requiresExplicitPlacement = this.dragRequiresExplicitConfirmation;

        if (this.dragMode === 'wo' && this.isPointInTrayCancelZone(clientX, clientY)) {
            this.stopAutoScrollLoop();
            this.resetDragState();
            event.preventDefault();
            return;
        }

        const dy = clientY - this.dragStartClientY;
        const hoursDelta = (dy / this.dragDayBodyHeight) * 24;

        const finalDayIndex =
            this.dragCurrentDayIndex != null
                ? this.dragCurrentDayIndex
                : this.dragStartDayIndex;

        const dayObj = this.calendarDays[finalDayIndex];
        const baseDay = new Date(dayObj.date);

        // If user did not move enough, treat as no drag
        if (!this.dragHasMoved) {
            this.stopAutoScrollLoop();
            if (
                requiresExplicitPlacement &&
                (this.pendingSchedulePlacement || this._pendingRegrabPlacement)
            ) {
                if (this._pendingRegrabPlacement) {
                    this.cachePendingSchedulePlacement(
                        this._pendingRegrabPlacement
                    );
                    this._pendingRegrabPlacement = null;
                }
                this.freezeGhostForConfirmation();
            } else {
                this.resetDragState();
            }
            event.preventDefault();
            return;
        }

        if (this.dragMode === 'event') {
            const id = this.draggingEventId;
            const startLocal = this.dragStartLocal;

            const newLocal = new Date(baseDay);
            newLocal.setHours(
                startLocal.getHours(),
                startLocal.getMinutes(),
                0,
                0
            );

            const millisDelta = hoursDelta * 60 * 60 * 1000;
            newLocal.setTime(newLocal.getTime() + millisDelta);

            const minutes = newLocal.getMinutes();
            const roundedMinutes = Math.round(minutes / 15) * 15;
            newLocal.setMinutes(roundedMinutes, 0, 0);

            const isoString = this.toUserIsoString(newLocal);
            const duration =
                this.dragDurationHours ||
                this.dragPreviewDurationHours ||
                this.computeDurationHours(startLocal, this.dragStartEndLocal);
            const endLocal = new Date(newLocal);
            endLocal.setTime(endLocal.getTime() + duration * 60 * 60 * 1000);

            if (requiresExplicitPlacement) {
                this.cachePendingSchedulePlacement({
                    type: 'event',
                    appointmentId: id,
                    startIso: isoString,
                    endIso: this.toUserIsoString(endLocal),
                    dayIndex: finalDayIndex,
                    durationHours: duration,
                    title: this.dragGhostTitle,
                    typeClass: this.dragGhostTypeClass
                });
            } else {
                this.appointments = this.appointments.map(a => {
                    if (a.appointmentId === id) {
                        return {
                            ...a,
                            newStart: isoString,
                            disableSave: false
                        };
                    }
                    return a;
                });

                if (
                    this.selectedAppointment &&
                    this.selectedAppointment.appointmentId === id
                ) {
                    this.selectedAppointment = {
                        ...this.selectedAppointment,
                        newStart: isoString,
                        disableSave: false
                    };
                }

                this.handleReschedule({ target: { dataset: { id } } });
            }
        } else if (this.dragMode === 'resize') {
            const id = this.draggingEventId;
            if (id && this.dragStartLocal) {
                const startLocal = new Date(baseDay);
                startLocal.setHours(
                    this.dragStartLocal.getHours(),
                    this.dragStartLocal.getMinutes(),
                    0,
                    0
                );

                let durationHours =
                    this.dragPreviewDurationHours || this.dragDurationHours || 1;

                const newEnd = new Date(startLocal);
                newEnd.setTime(
                    newEnd.getTime() + durationHours * 60 * 60 * 1000
                );

                const roundedMinutes =
                    Math.round(newEnd.getMinutes() / 15) * 15;
                newEnd.setMinutes(roundedMinutes, 0, 0);

                this.updateAppointmentEndTime(id, this.toUserIsoString(newEnd));
            }
        } else if (this.dragMode === 'wo') {
            const workOrderId = this.draggingWorkOrderId;
            if (workOrderId) {
                const dayEl = this.template.querySelector(
                    `.sfs-calendar-day[data-day-index="${finalDayIndex}"]`
                );
                const dayBodyEl = dayEl
                    ? dayEl.querySelector('.sfs-calendar-day-body')
                    : null;
                const bodyRect = dayBodyEl
                    ? dayBodyEl.getBoundingClientRect()
                    : null;

                let dropLocal =
                    this.dragPreviewLocal != null
                        ? new Date(this.dragPreviewLocal)
                        : null;

                if (!dropLocal && bodyRect) {
                    const usableHeight =
                        bodyRect.height || this.dragDayBodyHeight || 1;
                    const startHour = this.calendarStartHour;
                    const totalHours =
                        this.calendarEndHour - this.calendarStartHour;

                    const relativeY = Math.max(
                        0,
                        Math.min(
                            usableHeight,
                            clientY - (bodyRect.top || 0)
                        )
                    );

                    const hourFraction =
                        startHour + (relativeY / usableHeight) * totalHours;
                    const hours = Math.floor(hourFraction);
                    const minutes = Math.round((hourFraction - hours) * 60);

                    dropLocal = new Date(baseDay);
                    dropLocal.setHours(hours, minutes, 0, 0);
                }

                if (!dropLocal) {
                    dropLocal = new Date(baseDay);
                    dropLocal.setHours(9, 0, 0, 0);
                    const millisDelta = hoursDelta * 60 * 60 * 1000;
                    dropLocal.setTime(dropLocal.getTime() + millisDelta);
                }

                const minutes = dropLocal.getMinutes();
                const roundedMinutes = Math.round(minutes / 15) * 15;
                dropLocal.setMinutes(roundedMinutes, 0, 0);

                const dropEnd = new Date(dropLocal);
                const durationHours =
                    this.dragPreviewDurationHours ||
                    this.defaultWorkOrderDurationHours;
                dropEnd.setTime(
                    dropEnd.getTime() + durationHours * 60 * 60 * 1000
                );

                if (requiresExplicitPlacement) {
                    this.cachePendingSchedulePlacement({
                        type: 'wo',
                        workOrderId,
                        visitAppointmentId: this.getSelectedVisitAppointmentId(
                            this.findRecordByWorkOrderId(workOrderId)
                        ),
                        startIso: this.toUserIsoString(dropLocal),
                        endIso: this.toUserIsoString(dropEnd),
                        dayIndex: finalDayIndex,
                        durationHours,
                        title: this.dragGhostTitle,
                        typeClass: this.dragGhostTypeClass
                    });
                } else {
                    this.scheduleSelectedVisitPlacement(
                        workOrderId,
                        this.toUserIsoString(dropLocal),
                        this.toUserIsoString(dropEnd),
                        this.getSelectedVisitAppointmentId(
                            this.findRecordByWorkOrderId(workOrderId)
                        )
                    );
                }
            }
        }

        if (requiresExplicitPlacement && this.showDragConfirmActions) {
            this.freezeGhostForConfirmation();
        } else {
            this.resetDragState();
        }
        event.preventDefault();
    }

    cachePendingSchedulePlacement(placement) {
        if (!placement) {
            return;
        }

        this.pendingSchedulePlacement = placement;
        this._pendingRegrabPlacement = placement;
        this.isAwaitingScheduleConfirmation = true;
        this.updateGhostFromPlacement();
        this.attachGhostAnchorUpdater();
    }

    freezeGhostForConfirmation() {
        this.stopAutoScrollLoop();
        this.unregisterGlobalDragListeners();
        this.dragMode = null;
        this.dragStartClientX = null;
        this.dragStartClientY = null;
        this.dragHasMoved = false;
        this.showTrayCancelZone = false;
        this.isHoveringCancelZone = false;
        this.updateGhostFromPlacement();
    }

    confirmPendingSchedule() {
        const placement = this.pendingSchedulePlacement;
        if (!placement) {
            return;
        }

        this.pendingSchedulePlacement = null;
        this.isAwaitingScheduleConfirmation = false;
        this.dragRequiresExplicitConfirmation = false;

        if (placement.type === 'event') {
            const id = placement.appointmentId;
            if (!id || !placement.startIso) {
                this.resetDragState();
                return;
            }

            this.appointments = this.appointments.map(a => {
                if (a.appointmentId === id) {
                    return {
                        ...a,
                        newStart: placement.startIso,
                        disableSave: false
                    };
                }
                return a;
            });

            if (
                this.selectedAppointment &&
                this.selectedAppointment.appointmentId === id
            ) {
                this.selectedAppointment = {
                    ...this.selectedAppointment,
                    newStart: placement.startIso,
                    disableSave: false
                };
            }

            this.resetDragState();
            this.handleReschedule({ target: { dataset: { id } } });
            this.schedulePreviewCardId = null;
            this.schedulePreviewListMode = null;
            return;
        }

        if (placement.type === 'wo') {
            const { workOrderId, startIso, endIso, visitAppointmentId } = placement;
            if (!workOrderId || !startIso || !endIso) {
                this.resetDragState();
                return;
            }

            this.resetDragState();
            this.scheduleSelectedVisitPlacement(
                workOrderId,
                startIso,
                endIso,
                visitAppointmentId
            );
            this.schedulePreviewCardId = null;
            this.schedulePreviewListMode = null;
        }
    }

    cancelPendingSchedule() {
        const cardId = this.schedulePreviewCardId;
        const listMode = this.schedulePreviewListMode;

        this.pendingSchedulePlacement = null;
        this.isAwaitingScheduleConfirmation = false;
        this.dragRequiresExplicitConfirmation = false;
        this.detachGhostAnchorUpdater();
        this.resetDragState();

        if (listMode) {
            this.listMode = listMode;
        }

        this.updateActiveTabState('list');

        if (cardId) {
            this.safeSetTimeout(() => this.scrollCardIntoView(cardId), 50);
        }

        this.schedulePreviewCardId = null;
        this.schedulePreviewListMode = null;
    }

    attachGhostAnchorUpdater() {
        if (this._boundGhostAnchorUpdater) {
            this.startGhostAnchorLoop();
            return;
        }

        this._boundGhostAnchorUpdater = () => this.updateGhostFromPlacement();

        const wrapper = this.template.querySelector('.sfs-calendar-days-wrapper');
        if (wrapper) {
            wrapper.addEventListener('scroll', this._boundGhostAnchorUpdater);
        }

        window.addEventListener('resize', this._boundGhostAnchorUpdater);

        this.startGhostAnchorLoop();
    }

    detachGhostAnchorUpdater() {
        if (!this._boundGhostAnchorUpdater) {
            return;
        }

        const wrapper = this.template.querySelector('.sfs-calendar-days-wrapper');
        if (wrapper) {
            wrapper.removeEventListener('scroll', this._boundGhostAnchorUpdater);
        }

        window.removeEventListener('resize', this._boundGhostAnchorUpdater);
        this._boundGhostAnchorUpdater = null;

        this.stopGhostAnchorLoop();
    }

    updateGhostFromPlacement() {
        if (!this.pendingSchedulePlacement || !this.dragGhostVisible) {
            return;
        }

        const placement = this.pendingSchedulePlacement;
        const { startIso, endIso, dayIndex, durationHours, title, typeClass } =
            placement;

        const startLocal = startIso
            ? this.convertUtcToUserLocal(startIso)
            : null;
        const endLocal = endIso ? this.convertUtcToUserLocal(endIso) : null;

        const targetDayIndex =
            dayIndex != null ? dayIndex : this.resolveDayIndexFromDate(startLocal);

        if (targetDayIndex == null || !this.calendarDays[targetDayIndex]) {
            return;
        }

        const calendarEl = this.template.querySelector('.sfs-calendar');
        const dayEl = this.template.querySelector(
            `.sfs-calendar-day[data-day-index="${targetDayIndex}"]`
        );
        const dayBodyEl = dayEl
            ? dayEl.querySelector('.sfs-calendar-day-body')
            : null;

        if (!dayEl || !dayBodyEl || !startLocal || !endLocal || !calendarEl) {
            return;
        }
        
        const dayRect = dayEl.getBoundingClientRect();
        const bodyRect = dayBodyEl.getBoundingClientRect();
        const totalHours = this.calendarEndHour - this.calendarStartHour;
        const ghostDuration =
            durationHours || this.computeDurationHours(startLocal, endLocal);

        let hourFraction =
            startLocal.getHours() + startLocal.getMinutes() / 60;
        if (hourFraction < this.calendarStartHour) {
            hourFraction = this.calendarStartHour;
        }
        if (hourFraction > this.calendarEndHour) {
            hourFraction = this.calendarEndHour;
        }

        const bodyHeight = bodyRect.height || 1;
        const topRatio =
            (hourFraction - this.calendarStartHour) / totalHours;
        const yWithinBody = topRatio * bodyHeight;
        const ghostHeight = (ghostDuration / totalHours) * bodyHeight;

        let ghostX = dayRect.left + dayRect.width / 2;
        let ghostY = bodyRect.top + yWithinBody;

        const anchorRect = this.getGhostAnchorRect();

        if (anchorRect) {
            ghostX -= anchorRect.left;
            ghostY -= anchorRect.top;
        }

        this.showDragGhost(
            ghostX,
            ghostY,
            title || this.dragGhostTitle,
            this.formatTimeRange(startLocal, endLocal),
            typeClass || this.dragGhostTypeClass,
            this.dragGhostWidth,
            ghostHeight || this.dragGhostHeight,
            true
        );
    }

    getGhostAnchorRect() {
        const timeline = this.template.querySelector('.sfs-calendar');
        if (timeline) {
            return timeline.getBoundingClientRect();
        }

        const weekGrid = this.template.querySelector('.sfs-weekgrid');
        return weekGrid ? weekGrid.getBoundingClientRect() : null;
    }

    computeGhostPointerOffsetFromCalendar(
        dayIndex,
        startLocal,
        durationHours,
        clientY,
        fallbackHeight,
        fallbackOffset
    ) {
        let offsetWithinGhost = fallbackOffset || 0;
        let ghostHeight = fallbackHeight;

        try {
            const dayEl = this.template.querySelector(
                `.sfs-calendar-day[data-day-index="${dayIndex}"]`
            );
            const bodyEl = dayEl
                ? dayEl.querySelector('.sfs-calendar-day-body')
                : null;
            const bodyRect = bodyEl
                ? bodyEl.getBoundingClientRect()
                : null;

            if (bodyRect && startLocal) {
                const totalHours = this.calendarEndHour - this.calendarStartHour || 24;
                const startHourFraction =
                    startLocal.getHours() + startLocal.getMinutes() / 60;
                const clampedHour = Math.min(
                    Math.max(startHourFraction, this.calendarStartHour),
                    this.calendarEndHour
                );
                const yWithinBody =
                    ((clampedHour - this.calendarStartHour) / totalHours) *
                    (bodyRect.height || 1);

                offsetWithinGhost = clientY - (bodyRect.top + yWithinBody);
                ghostHeight =
                    ((durationHours || this.dragGhostHeight || 0) / totalHours) *
                    (bodyRect.height || 1);

                this.dragDayBodyTop = bodyRect.top;
                this.dragDayBodyHeight = bodyRect.height || this.dragDayBodyHeight;

                if (dayEl) {
                    const dayRect = dayEl.getBoundingClientRect();
                    this.dragDayWidth = dayRect.width || this.dragDayWidth;
                }
            }
        } catch (err) {
            // eslint-disable-next-line no-console
            console.warn('Failed to compute calendar offset for ghost drag', err);
        }

        return {
            offsetWithinGhost: Math.max(offsetWithinGhost || 0, 0),
            ghostHeight
        };
    }

    startGhostAnchorLoop() {
        this.stopGhostAnchorLoop();

        const step = () => {
            if (!this.pendingSchedulePlacement || !this.dragGhostVisible) {
                this._ghostAnchorFrame = null;
                return;
            }

            this.updateGhostFromPlacement();
            this._ghostAnchorFrame = requestAnimationFrame(step);
        };

        this._ghostAnchorFrame = requestAnimationFrame(step);
    }

    stopGhostAnchorLoop() {
        if (this._ghostAnchorFrame) {
            cancelAnimationFrame(this._ghostAnchorFrame);
            this._ghostAnchorFrame = null;
        }
    }

    resolveDayIndexFromDate(date) {
        if (!date || !this.calendarDays || !this.calendarDays.length) {
            return null;
        }

        const target = `${date.getFullYear()}-${this.pad2(
            date.getMonth() + 1
        )}-${this.pad2(date.getDate())}`;

        const matchIndex = this.calendarDays.findIndex(d => d.date === target);
        return matchIndex >= 0 ? matchIndex : null;
    }

    handleGhostPointerDown(event) {
        if (
            event.target &&
            event.target.closest('.sfs-drag-ghost__action')
        ) {
            return;
        }

        // Allow re-grabbing the scheduling ghost even if the awaiting flag was
        // cleared, as long as a pending placement exists.
        const placement = this.pendingSchedulePlacement;
        if (!placement) {
            return;
        }

        // Re-grabs should stay in the explicit confirmation flow so the ✓ / ✕
        // controls remain the single way to finish or cancel placement.
        this.dragRequiresExplicitConfirmation = true;

        this._pendingRegrabPlacement = placement;

        const point = this.getClientPoint(event);
        if (!point) {
            return;
        }

        event.preventDefault();
        event.stopPropagation();

        // Remove anchoring before converting the pending placement back into a
        // live drag so the ghost follows the pointer instead of snapping back
        // to its cached position while dragging again.
        this.detachGhostAnchorUpdater();
        this.pendingSchedulePlacement = null;
        this.isAwaitingScheduleConfirmation = false;

        const startLocal = placement.startIso
            ? this.convertUtcToUserLocal(placement.startIso)
            : null;
        const endLocal = placement.endIso
            ? this.convertUtcToUserLocal(placement.endIso)
            : null;

        const dragTimeLabel =
            startLocal && endLocal
                ? this.formatTimeRange(startLocal, endLocal)
                : this.dragGhostTime;

        // Prefer deriving the pointer offset from the calendar geometry so the
        // ghost aligns with the actual timeslot, even if CSS transforms or
        // anchoring apply to the ghost element itself. Fall back to the ghost
        // element’s own bounds if the calendar column cannot be measured.
        let offsetWithinGhost = null;
        let ghostHeight = this.dragGhostHeight;

        try {
            const dayEl = this.template.querySelector(
                `.sfs-calendar-day[data-day-index="${placement.dayIndex}"]`
            );
            const bodyEl = dayEl
                ? dayEl.querySelector('.sfs-calendar-day-body')
                : null;
            const bodyRect = bodyEl
                ? bodyEl.getBoundingClientRect()
                : null;

            if (startLocal && bodyRect) {
                const totalHours =
                    this.calendarEndHour - this.calendarStartHour || 24;
                const startHourFraction =
                    startLocal.getHours() + startLocal.getMinutes() / 60;
                const clampedHour = Math.min(
                    Math.max(startHourFraction, this.calendarStartHour),
                    this.calendarEndHour
                );
                const yWithinBody =
                    ((clampedHour - this.calendarStartHour) / totalHours) *
                    (bodyRect.height || 1);

                // Offset between the pointer and the top of the ghost's
                // intended placement within the calendar column.
                offsetWithinGhost = point.clientY - (bodyRect.top + yWithinBody);
                this.dragDayBodyTop = bodyRect.top;
                this.dragDayBodyHeight =
                    bodyRect.height || this.dragDayBodyHeight;
                ghostHeight =
                    ((placement.durationHours || this.dragGhostHeight) /
                        totalHours) *
                    (bodyRect.height || 1);

                // Keep the ghost sizing in sync with the measured column so
                // the offset math remains accurate during drag.
                this.dragGhostHeight = ghostHeight;
            }
        } catch (err) {
            // If measurements fail for any reason (e.g., DOM not ready), fall
            // back to the ghost element so the drag can continue without
            // crashing the page.
            // eslint-disable-next-line no-console
            console.warn('Failed to measure calendar for ghost drag', err);
        }

        if (offsetWithinGhost == null) {
            const ghostRect =
                event.currentTarget &&
                typeof event.currentTarget.getBoundingClientRect === 'function'
                    ? event.currentTarget.getBoundingClientRect()
                    : null;

            const anchorRect = this.getGhostAnchorRect();
            const anchorTop = anchorRect ? anchorRect.top : 0;

            offsetWithinGhost = ghostRect
                ? point.clientY - ghostRect.top
                : point.clientY - (this.dragGhostAnchoredToCalendar
                      ? this.dragGhostY + anchorTop
                      : this.dragGhostY);

            ghostHeight = (ghostRect && ghostRect.height) || this.dragGhostHeight;
        }

        // Do not clamp to the ghost height; retaining the exact offset from
        // the intended start keeps the top edge aligned with the displayed
        // time while dragging, even if the measured height differs from the
        // rendered element. Ensure it never becomes NaN.
        this.dragGhostPointerOffsetY = Math.max(offsetWithinGhost || 0, 0);

        this.showDragGhost(
            point.clientX,
            point.clientY - this.dragGhostPointerOffsetY,
            placement.title || this.dragGhostTitle,
            dragTimeLabel,
            placement.typeClass || this.dragGhostTypeClass,
            this.dragGhostWidth,
            this.dragGhostHeight
        );

        this.prepareGhostDragFromPlacement(point, placement);
    }

    prepareGhostDragFromPlacement(startPoint, placement = null) {
        const targetPlacement = placement || this.pendingSchedulePlacement;
        if (!targetPlacement) {
            return;
        }

        const startLocal = targetPlacement.startIso
            ? this.convertUtcToUserLocal(targetPlacement.startIso)
            : null;
        const endLocal = targetPlacement.endIso
            ? this.convertUtcToUserLocal(targetPlacement.endIso)
            : null;

        const durationHours = targetPlacement.durationHours
            ? targetPlacement.durationHours
            : this.computeDurationHours(startLocal, endLocal);

        const dayIndex =
            targetPlacement.dayIndex != null
                ? targetPlacement.dayIndex
                : this.resolveDayIndexFromDate(startLocal);

        if (dayIndex == null) {
            return;
        }

        this.dragMode = targetPlacement.type === 'event' ? 'event' : 'wo';
        this.dragRequiresExplicitConfirmation = true;
        this.dragStartDayIndex = dayIndex;
        this.dragCurrentDayIndex = dayIndex;
        this.dragStartLocal = startLocal;
        this.dragStartEndLocal = endLocal;
        this.dragPreviewLocal = startLocal;
        this.dragPreviewDurationHours = durationHours;
        this.dragDurationHours = durationHours;
        this.dragStartClientX = startPoint.clientX;
        this.dragStartClientY = startPoint.clientY;
        this.dragHasMoved = false;
        this.isAwaitingScheduleConfirmation = true;

        if (targetPlacement.type === 'event') {
            this.draggingEventId = targetPlacement.appointmentId;
            this.draggingWorkOrderId = null;
        } else {
            this.draggingWorkOrderId = targetPlacement.workOrderId;
            this.draggingEventId = null;
        }

        const dayEl = this.template.querySelector(
            `.sfs-calendar-day[data-day-index="${dayIndex}"]`
        );
        const bodyEl = dayEl
            ? dayEl.querySelector('.sfs-calendar-day-body')
            : null;
        const dayRect = dayEl ? dayEl.getBoundingClientRect() : null;
        const bodyRect = bodyEl ? bodyEl.getBoundingClientRect() : null;

        if (dayRect && bodyRect) {
            this.dragDayBodyHeight = bodyRect.height || this.dragDayBodyHeight;
            this.dragDayBodyTop = bodyRect.top;
            this.dragDayWidth = dayRect.width || this.dragDayWidth;
        }

        this.registerGlobalDragListeners();
    }

    scrollCardIntoView(cardId) {
        if (!cardId) {
            return;
        }

        const cardSelector = `.sfs-card[data-card-id="${cardId}"]`;
        const cardEl = this.template.querySelector(cardSelector);

        if (cardEl && typeof cardEl.scrollIntoView === 'function') {
            cardEl.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
    }

    cachePendingSchedulePlacement(placement) {
        if (!placement) {
            return;
        }

        this.pendingSchedulePlacement = placement;
        this.isAwaitingScheduleConfirmation = true;
        this.updateGhostFromPlacement();
        this.attachGhostAnchorUpdater();
    }

    freezeGhostForConfirmation() {
        this.stopAutoScrollLoop();
        this.unregisterGlobalDragListeners();
        this.dragMode = null;
        this.dragStartClientX = null;
        this.dragStartClientY = null;
        this.dragHasMoved = false;
        this.showTrayCancelZone = false;
        this.isHoveringCancelZone = false;
        this.updateGhostFromPlacement();
    }

    confirmPendingSchedule() {
        const placement = this.pendingSchedulePlacement;
        if (!placement) {
            return;
        }

        this.pendingSchedulePlacement = null;
        this.isAwaitingScheduleConfirmation = false;
        this.dragRequiresExplicitConfirmation = false;

        if (placement.type === 'event') {
            const id = placement.appointmentId;
            if (!id || !placement.startIso) {
                this.resetDragState();
                return;
            }

            this.appointments = this.appointments.map(a => {
                if (a.appointmentId === id) {
                    return {
                        ...a,
                        newStart: placement.startIso,
                        disableSave: false
                    };
                }
                return a;
            });

            if (
                this.selectedAppointment &&
                this.selectedAppointment.appointmentId === id
            ) {
                this.selectedAppointment = {
                    ...this.selectedAppointment,
                    newStart: placement.startIso,
                    disableSave: false
                };
            }

            this.resetDragState();
            this.handleReschedule({ target: { dataset: { id } } });
            this.schedulePreviewCardId = null;
            this.schedulePreviewListMode = null;
            return;
        }

        if (placement.type === 'wo') {
            const { workOrderId, startIso, endIso, visitAppointmentId } = placement;
            if (!workOrderId || !startIso || !endIso) {
                this.resetDragState();
                return;
            }

            this.resetDragState();
            this.scheduleSelectedVisitPlacement(
                workOrderId,
                startIso,
                endIso,
                visitAppointmentId
            );
            this.schedulePreviewCardId = null;
            this.schedulePreviewListMode = null;
        }
    }

    cancelPendingSchedule() {
        const cardId = this.schedulePreviewCardId;
        const listMode = this.schedulePreviewListMode;

        this.pendingSchedulePlacement = null;
        this.isAwaitingScheduleConfirmation = false;
        this.dragRequiresExplicitConfirmation = false;
        this.detachGhostAnchorUpdater();
        this.resetDragState();

        if (listMode) {
            this.listMode = listMode;
        }

        this.updateActiveTabState('list');

        if (cardId) {
            this.safeSetTimeout(() => this.scrollCardIntoView(cardId), 50);
        }

        this.schedulePreviewCardId = null;
        this.schedulePreviewListMode = null;
    }

    scrollCardIntoView(cardId) {
        if (!cardId) {
            return;
        }

        const cardSelector = `.sfs-card[data-card-id="${cardId}"]`;
        const cardEl = this.template.querySelector(cardSelector);

        if (cardEl && typeof cardEl.scrollIntoView === 'function') {
            cardEl.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
    }

    resetDragState() {
        // When a pending placement is waiting for explicit confirmation, keep the
        // ghost visible and anchored so it can only be dismissed via the
        // confirmation controls. Other gestures (like panning the calendar)
        // should stop any active drag interactions without clearing the ghost.
        if (this.pendingSchedulePlacement && this.isAwaitingScheduleConfirmation) {
            this.stopAutoScrollLoop();
            this.unregisterGlobalDragListeners();
            this.dragMode = null;
            this.dragStartClientX = null;
            this.dragStartClientY = null;
            this.dragHasMoved = false;
            this.showTrayCancelZone = false;
            this.isHoveringCancelZone = false;
            this.isPressingForDrag = false;
            this._pendingDrag = null;
            this.clearLongPressTimer();
            return;
        }

        this.dragMode = null;
        this.draggingEventId = null;
        this.draggingWorkOrderId = null;
        this.dragStartClientX = null;
        this.dragStartClientY = null;
        this.dragStartDayIndex = null;
        this.dragCurrentDayIndex = null;
        this.dragDayWidth = null;
        this.dragDayBodyHeight = null;
        this.dragStartLocal = null;
        this.dragStartEndLocal = null;
        this.dragPreviewLocal = null;
        this.dragPreviewDurationHours = null;
        this.dragDurationHours = null;
        this.dragHasMoved = false;
        this.dragGhostPointerOffsetY = 0;
        this.isPressingForDrag = false;
        this._pendingDrag = null;
        this._pendingRegrabPlacement = null;
        this.clearLongPressTimer();
        this.hideDragGhost();
        this.dragDayBodyTop = null;
        this.showTrayCancelZone = false;
        this.isHoveringCancelZone = false;
        this.dragRequiresExplicitConfirmation = false;
        this.isAwaitingScheduleConfirmation = false;
        this.pendingSchedulePlacement = null;
        this.stopAutoScrollLoop();
        this.unregisterGlobalDragListeners();
        this.detachGhostAnchorUpdater();
        this.updateSelectedEventStyles();

        if (this._trayOpenBeforeDrag) {
            this.pullTrayOpen = true;
        }

        if (this.pullTrayOpen && this._trayWasExpandedBeforeDrag) {
            this.pullTrayPeek = false;
        }

        this._trayWasExpandedBeforeDrag = false;
        this._trayOpenBeforeDrag = false;
    }



    // ======= DATA LOAD =======

    shouldBuildCalendarModelAfterDataLoad() {
        return this.isCalendarTabActive || this.hasCalendarModel;
    }

    get hasCalendarModel() {
        return Boolean(this.calendarDays && this.calendarDays.length);
    }

    ensureCalendarModelForActiveTab() {
        if (!this.isCalendarTabActive || this.isLoading || this.hasCalendarModel) {
            return;
        }

        if (!this.timelineStartDate && !this.weekStartDate) {
            this.centerCalendarOnToday(false);
        }

        this.buildCalendarModel();
    }

    loadAppointments(options = {}) {
        const { preserveScroll = false, dataScope = this.getDataScopeForTab(this.activeTab) } = options;
        const previousScrollY = preserveScroll ? window.scrollY : null;
        const previousActiveUserId = this.activeUserId;
        this.isLoading = true;
        this.selectedAppointment = null;
        this.selectedAbsence = null;
        this.quoteLineItemsExpanded = {};

        getMyAppointmentsOnlineScoped({
            targetUserId: this.activeUserId,
            includeHistory: false,
            dataScope: dataScope
        })
            .then(result => {
                const appts =
                    result && result.appointments ? result.appointments : [];

                this.userTimeZoneId =
                    result && result.userTimeZoneId ? result.userTimeZoneId : null;
                this.userTimeZoneShort = this.computeTimeZoneShort();

                this.currentUserId =
                    result && result.debug ? result.debug.currentUserId : null;
                this.activeUserId =
                    result && result.viewingUserId
                        ? result.viewingUserId
                        : this.activeUserId || this.currentUserId;
                this.managerTeam =
                    result && result.teamMembers ? result.teamMembers : [];
                this.isManager = Boolean(result && result.isManager);
                this.viewingUserName = this.resolveViewingName();

                if (this.isViewingAsOther) {
                    const selected = this.managerTeam.find(
                        m => m.userId === this.activeUserId
                    );
                    this.selectedManagerUserId = selected
                        ? selected.userId
                        : this.selectedManagerUserId;
                    this.selectedManagerUserName = selected
                        ? selected.name
                        : this.selectedManagerUserName;
                } else {
                    this.selectedManagerUserId = null;
                    this.selectedManagerUserName = '';
                }

                if (
                    previousActiveUserId &&
                    previousActiveUserId !== this.activeUserId
                ) {
                    this.historyItems = [];
                    this.historySearchFilter = '';
                    this.historySearchInput = '';
                    this.historyLoaded = false;
                }

                this.loadedDataScope = dataScope;

                this.debugInfo =
                    result && result.debug
                        ? result.debug
                        : { note: 'No debug info.' };

                // Unscheduled Work Orders for tray
                const unscheduled =
                    result && result.unscheduledWorkOrders
                        ? result.unscheduledWorkOrders
                        : [];
                const unscheduledWithSubject = unscheduled.filter(wo =>
                    this.hasWorkOrderSubject(wo)
                );
                this.unscheduledWorkOrders = unscheduledWithSubject.map(wo => {
                    const clone = { ...wo };
                    clone.isCrewAppointment = Boolean(wo.hasCrewAssignment);
                    clone.serviceAppointmentCount = wo.serviceAppointmentCount || 0;
                    clone.visitScheduleDates = Array.isArray(wo.visitScheduleDates)
                        ? wo.visitScheduleDates
                        : [];
                    clone.unscheduledServiceAppointmentCount =
                        wo.unscheduledServiceAppointmentCount || 0;
                    clone.allServiceAppointmentsReturnRequired = Boolean(
                        wo.allServiceAppointmentsReturnRequired
                    );
                    clone.hasUnscheduledNonReturnAppointment = Boolean(
                        wo.hasUnscheduledNonReturnAppointment
                    );
                    clone.hasAnyReturnVisitRequired = Boolean(
                        wo.hasAnyReturnVisitRequired
                    );
                    clone.recordTypeName = wo.recordTypeName;
                    clone.needsReturnVisitScheduling = Boolean(
                        wo.needsReturnVisitScheduling
                    );
                    clone.workOrderSubject = wo.subject;
                    clone.workOrderStage =
                        wo.workOrderStage || wo.stage || null;
                    clone.cardId = `wo-${wo.workOrderId}`;
                    clone.hasAppointment = false;
                    clone.isExpanded = false;
                    clone.completedVisitCount = wo.completedVisitCount || 0;
                    clone.visitNumber = clone.serviceAppointmentCount || 0;
                    clone.visitLabel =
                        clone.serviceAppointmentCount > 0
                            ? `Visit ${clone.serviceAppointmentCount}`
                            : null;
                    clone.workTypeName = wo.workTypeName;
                    clone.quoteLineItems = this.normalizeQuoteLineItems(
                        wo.quoteLineItems
                    );
                    clone.contactPhoneHref = wo.contactPhone
                        ? `tel:${wo.contactPhone.replace(/\D/g, '')}`
                        : null;
                    clone.contactEmailHref = wo.contactEmail
                        ? `mailto:${encodeURIComponent(wo.contactEmail)}`
                        : null;

                    const reporter = this.parseReporterInfo(
                        wo.reporterContactInfo
                    );
                    clone.reporterContactInfo = this.normalizeReporterContactValue(
                        wo.reporterContactInfo
                    );
                    clone.reporterName = reporter.name;
                    clone.reporterPhone = reporter.phone;
                    clone.reporterPhoneDisplay = reporter.phoneDisplay;
                    clone.reporterPhoneHref = reporter.phoneHref;
                    clone.reporterEmail = reporter.email;
                    clone.reporterEmailHref = reporter.emailHref;
                    if (!wo.contactId && reporter) {
                        clone.contactName =
                            clone.contactName ||
                            reporter.name ||
                            clone.reporterContactInfo;
                        clone.contactPhone = clone.contactPhone
                            ? clone.contactPhone
                            : reporter.phoneDisplay;
                        clone.contactEmail = clone.contactEmail
                            ? clone.contactEmail
                            : reporter.email;
                        clone.contactPhoneHref = clone.contactPhoneHref
                            ? clone.contactPhoneHref
                            : reporter.phoneHref;
                        clone.contactEmailHref = clone.contactEmailHref
                            ? clone.contactEmailHref
                            : reporter.emailHref;
                    }
                    clone.hasDetailSection = Boolean(
                        clone.contactPhoneHref ||
                            clone.contactEmailHref ||
                            clone.reporterContactInfo
                    );
                    clone.canAddReporterContact =
                        this.canAddReporterContact(clone);
                    clone.latestServiceAppointmentTrackingNumber =
                        wo.latestServiceAppointmentTrackingNumber || null;
                    clone.workOrderTrackingNumber =
                        wo.workOrderTrackingNumber || null;
                    clone.opportunityTrackingNumber =
                        wo.opportunityTrackingNumber || null;
                    clone.opportunityNumber = wo.opportunityNumber || null;
                    clone.opportunityStage = wo.opportunityStage || null;
                    clone.dateProbeReceivedForRepairEval =
                        wo.dateProbeReceivedForRepairEval || null;
                    clone.dateQuoteSentToCustomer =
                        wo.dateQuoteSentToCustomer || null;
                    clone.quoteSentDateDisplay =
                        this.formatDateDisplay(wo.dateQuoteSentToCustomer);
                    clone.showQuoteSentDate = Boolean(
                        wo.dateQuoteSentToCustomer &&
                        this.resolveQuoteStatus(clone) === 'Quote Sent'
                    );
                    clone.loanerTrackingNumber = wo.loanerTrackingNumber || null;
                    clone.showOpportunityStage =
                        this.shouldShowOpportunityStage(clone);
                    clone.opportunityStageClass =
                        this.getOpportunityStageClass(clone);
                    clone.showOpportunityMeta =
                        this.shouldShowOpportunityMeta(clone);
                    clone.showRepairApprovedAction =
                        this.shouldShowRepairApprovedAction(clone);
                    clone.showExchangeApprovalAction =
                        this.shouldShowExchangeApprovalAction(clone);
                    clone.showRepairApprovalActions =
                        this.shouldShowRepairApprovalActions(clone);
                    clone.showConfirmShippingAction =
                        this.shouldShowConfirmShippingAction(clone);
                    clone.showMarkRepairSentAction =
                        this.shouldShowMarkRepairSentAction(clone);
                    Object.assign(clone, this.buildPoNumberState(clone));
                    Object.assign(clone, this.buildServiceSiteState(clone));

                    clone.fullAddress = this.composeFullAddress(wo);
                    clone.hasFullAddress = this.hasStreetValue(wo);
                    Object.assign(clone, this.normalizeShippingAddress(wo));
                    return this.applyAccountPresentation(clone);
                });

                const transferRequests =
                    result && result.transferRequests
                        ? result.transferRequests
                        : [];
                const submittedTransferRequests =
                    result && result.submittedTransferRequests
                        ? result.submittedTransferRequests
                        : [];

                this.transferRequests = transferRequests.map(req =>
                    this.normalizeTransferRequest(req)
                );
                this.submittedTransferRequests = submittedTransferRequests
                    .filter(req => !req.acceptedOn && !req.rejectedOn)
                    .map(req => this.normalizeTransferRequest(req));

                const absences =
                    result && result.absences ? result.absences : [];
                this.absences = absences.map(abs => ({
                    ...abs,
                    subject: abs.description || 'Absence',
                    newStart: abs.start,
                    newEnd: abs.endTime
                }));


                const appointmentsWithSubject = appts.filter(appt =>
                    this.hasWorkOrderSubject(appt)
                );

                this.appointments = appointmentsWithSubject.map(appt => {
                    const clone = { ...appt };

                    clone.newStart = appt.schedStart;
                    clone.disableSave = true;
                    clone.workOrderId = appt.workOrderId;
                    clone.recordUrl =
                        '/lightning/r/ServiceAppointment/' +
                        appt.appointmentId +
                        '/view';

                    clone.workOrderStatus = appt.workOrderStatus;
                    clone.workOrderStage =
                        appt.workOrderStage || appt.stage || null;

                    clone.isExpanded = false;

                    const typeClass = this.getEventTypeClass(appt.workTypeName);
                    clone.workTypeClass = `sfs-worktype ${typeClass || ''}`.trim();
                    clone.completedVisitCount = appt.completedVisitCount || 0;
                    clone.serviceAppointmentCount =
                        appt.serviceAppointmentCount || 0;
                    clone.visitScheduleDates = Array.isArray(appt.visitScheduleDates)
                        ? appt.visitScheduleDates
                        : [];
                    clone.visitNumber = clone.serviceAppointmentCount || 0;
                    clone.visitLabel =
                        clone.serviceAppointmentCount > 0
                            ? `Visit ${clone.serviceAppointmentCount}`
                            : null;

                    if (appt.contactPhone) {
                        const digits = appt.contactPhone.replace(/\D/g, '');
                        clone.contactPhoneHref = digits ? `tel:${digits}` : null;
                    } else {
                        clone.contactPhoneHref = null;
                    }

                    if (appt.contactEmail) {
                        clone.contactEmailHref = `mailto:${encodeURIComponent(
                            appt.contactEmail
                        )}`;
                    } else {
                        clone.contactEmailHref = null;
                    }

                    clone.reporterContactInfo = this.normalizeReporterContactValue(
                        appt.reporterContactInfo
                    );

                    const reporter = this.parseReporterInfo(
                        appt.reporterContactInfo
                    );
                    clone.reporterName = reporter.name;
                    clone.reporterPhone = reporter.phone;
                    clone.reporterPhoneDisplay = reporter.phoneDisplay;
                    clone.reporterPhoneHref = reporter.phoneHref;
                    clone.reporterEmail = reporter.email;
                    clone.reporterEmailHref = reporter.emailHref;
                    if (!appt.contactId && reporter) {
                        clone.contactName =
                            clone.contactName ||
                            reporter.name ||
                            clone.reporterContactInfo;
                        clone.contactPhone = clone.contactPhone
                            ? clone.contactPhone
                            : reporter.phoneDisplay;
                        clone.contactEmail = clone.contactEmail
                            ? clone.contactEmail
                            : reporter.email;
                        clone.contactPhoneHref = clone.contactPhoneHref
                            ? clone.contactPhoneHref
                            : reporter.phoneHref;
                        clone.contactEmailHref = clone.contactEmailHref
                            ? clone.contactEmailHref
                            : reporter.emailHref;
                    }
                    clone.hasDetailSection = Boolean(
                        clone.contactPhoneHref ||
                            clone.contactEmailHref ||
                            clone.reporterContactInfo
                    );
                    clone.canAddReporterContact =
                        this.canAddReporterContact(clone);
                    clone.workOrderNumber = appt.workOrderNumber;
                    clone.serviceAppointmentTrackingNumber =
                        appt.serviceAppointmentTrackingNumber || null;
                    clone.latestServiceAppointmentTrackingNumber =
                        appt.latestServiceAppointmentTrackingNumber || null;
                    clone.workOrderTrackingNumber =
                        appt.workOrderTrackingNumber || null;
                    clone.opportunityTrackingNumber =
                        appt.opportunityTrackingNumber || null;
                    clone.opportunityNumber = appt.opportunityNumber || null;
                    clone.opportunityStage = appt.opportunityStage || null;
                    clone.dateProbeReceivedForRepairEval =
                        appt.dateProbeReceivedForRepairEval || null;
                    clone.dateQuoteSentToCustomer =
                        appt.dateQuoteSentToCustomer || null;
                    clone.quoteSentDateDisplay =
                        this.formatDateDisplay(appt.dateQuoteSentToCustomer);
                    clone.showQuoteSentDate = Boolean(
                        appt.dateQuoteSentToCustomer &&
                        clone.workOrderStatus === 'Quote Sent'
                    );
                    clone.loanerTrackingNumber =
                        appt.loanerTrackingNumber || null;
                    clone.showOpportunityStage =
                        this.shouldShowOpportunityStage(clone);
                    clone.opportunityStageClass =
                        this.getOpportunityStageClass(clone);
                    clone.showOpportunityMeta =
                        this.shouldShowOpportunityMeta(clone);

                    clone.fullAddress = this.composeFullAddress(appt);
                    clone.hasFullAddress = this.hasStreetValue(appt);
                    Object.assign(clone, this.normalizeShippingAddress(appt));

                    const crewMembers = appt.crewMembers || [];
                    clone.crewMembers = crewMembers;
                    clone.crewOptions = crewMembers.map(m => ({
                        label: m.name,
                        value: m.serviceResourceId
                    }));
                    clone.selectedCrewMemberId = null;
                    clone.disableAssignTech = true;

                    clone.latestReturnVisitRequired = Boolean(
                        appt.latestReturnVisitRequired
                    );

                    clone.quoteLineItems = this.normalizeQuoteLineItems(
                        appt.quoteLineItems
                    );
                    clone.quoteAttachmentUrl = appt.quoteAttachmentDownloadUrl || null;
                    clone.quoteAttachmentDocumentId =
                        appt.quoteAttachmentDocumentId || null;
                    clone.hasQuoteAttachment = Boolean(
                        appt.hasQuoteAttachment ||
                            appt.workOrderStatus === 'Quote Attached' ||
                            appt.workOrderStatus === 'Ready to Ship'
                    );
                    clone.showGoToFilesAction = Boolean(
                        appt.quoteAttachmentDownloadUrl ||
                        (this.isQuoteAttachedAppointment(clone) && this.isProbeRepairRecord(clone))
                    );
                    clone.showQuoteActions =
                        clone.workOrderStatus === 'Quote Sent' ||
                        clone.workOrderStatus === 'Ready to Ship' ||
                        this.isQuoteAttachedAppointment(clone);
                    clone.showMarkQuoteSentAction =
                        this.shouldShowMarkQuoteSentAction(clone);
                    clone.showMarkPoAttachedAction =
                        this.shouldShowMarkPoAttached(clone);
                    clone.showCancelSaleAction =
                        this.shouldShowCancelSaleAction(clone);
                    clone.showRepairApprovedAction =
                        this.shouldShowRepairApprovedAction(clone);
                    clone.showExchangeApprovalAction =
                        this.shouldShowExchangeApprovalAction(clone);
                    clone.showRepairApprovalActions =
                        this.shouldShowRepairApprovalActions(clone);
                    clone.showConfirmShippingAction =
                        this.shouldShowConfirmShippingAction(clone);
                    clone.showMarkRepairSentAction =
                        this.shouldShowMarkRepairSentAction(clone);
                    Object.assign(clone, this.buildPoNumberState(clone));
                    Object.assign(clone, this.buildServiceSiteState(clone));
                    clone.opportunityRecordType = appt.opportunityRecordType || null;
                    clone.cardId = appt.appointmentId;
                    clone.hasAppointment = true;

                    return this.applyAccountPresentation(clone);
                });

                this.syncListModeWithOptions();

                if (!this.timelineStartDate && !this.weekStartDate) {
                    this.centerCalendarOnToday(false);
                }

                if (this.shouldBuildCalendarModelAfterDataLoad()) {
                    this.buildCalendarModel();
                } else {
                    this.calendarDays = [];
                    this.showNowLine = false;
                    this.nowLineStyle = '';
                }
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.debugInfo = {
                    note: 'Error calling getMyAppointmentsOnline',
                    errorMessage: message
                };
                this.appointments = [];
                this.calendarDays = [];
                this.unscheduledWorkOrders = [];
                this.absences = [];
                this.showToast('Error loading appointments', message, 'error');
            })
            .finally(() => {
                this.isLoading = false;

                if (preserveScroll && previousScrollY !== null) {
                    this.safeSetTimeout(() => {
                        window.scrollTo({
                            top: previousScrollY,
                            behavior: 'auto'
                        });
                    }, 0);
                }
            });
    }

    computeTimeZoneShort() {
        if (!this.userTimeZoneId) {
            return null;
        }
        try {
            const formatter = new Intl.DateTimeFormat('en-US', {
                timeZone: this.userTimeZoneId,
                timeZoneName: 'short'
            });
            const parts = formatter.formatToParts(new Date());
            const tzPart = parts.find(p => p.type === 'timeZoneName');
            return tzPart ? tzPart.value : this.userTimeZoneId;
        } catch (e) {
            return this.userTimeZoneId;
        }
    }

    resolveViewingName() {
        if (!this.isManager || !this.activeUserId) {
            return 'You';
        }

        if (this.currentUserId && this.activeUserId === this.currentUserId) {
            return 'You';
        }

        const match = (this.managerTeam || []).find(
            m => m.userId === this.activeUserId
        );
        return match ? match.name : 'Team Member';
    }

    convertUtcToUserLocal(dateLike) {
        const d = new Date(dateLike);

        if (!this.userTimeZoneId) {
            return d;
        }

        try {
            const formatter = new Intl.DateTimeFormat('en-US', {
                timeZone: this.userTimeZoneId,
                year: 'numeric',
                month: '2-digit',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',
                hour12: false
            });

            const parts = formatter.formatToParts(d).reduce((acc, part) => {
                acc[part.type] = part.value;
                return acc;
            }, {});

            return new Date(
                Number(parts.year),
                Number(parts.month) - 1,
                Number(parts.day),
                Number(parts.hour),
                Number(parts.minute),
                Number(parts.second),
                d.getMilliseconds()
            );
        } catch (e) {
            return d;
        }
    }

    getTimeZoneOffsetMinutes(date) {
        try {
            const formatter = new Intl.DateTimeFormat('en-US', {
                timeZone: this.userTimeZoneId,
                year: 'numeric',
                month: '2-digit',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',
                hour12: false
            });

            const parts = formatter.formatToParts(date).reduce((acc, part) => {
                acc[part.type] = part.value;
                return acc;
            }, {});

            const tzAsUtc = Date.UTC(
                Number(parts.year),
                Number(parts.month) - 1,
                Number(parts.day),
                Number(parts.hour),
                Number(parts.minute),
                Number(parts.second)
            );

            return (tzAsUtc - date.getTime()) / (60 * 1000);
        } catch (e) {
            // Default to the browser's current offset when we cannot parse the timezone
            return -date.getTimezoneOffset();
        }
    }

    toUserIsoString(dateLike) {
        const local = new Date(dateLike);

        if (!this.userTimeZoneId) {
            return local.toISOString();
        }

        // Adjust only when the browser's timezone differs from the user's
        const userOffsetMinutes = this.getTimeZoneOffsetMinutes(local);
        const browserOffsetMinutes = -local.getTimezoneOffset();
        const offsetDeltaMinutes = userOffsetMinutes - browserOffsetMinutes;

        if (offsetDeltaMinutes === 0) {
            return local.toISOString();
        }

        const utcMs = local.getTime() - offsetDeltaMinutes * 60 * 1000;
        return new Date(utcMs).toISOString();
    }

    getUserNow() {
        if (!this.userTimeZoneId) {
            return new Date();
        }

        try {
            const formatter = new Intl.DateTimeFormat('en-US', {
                timeZone: this.userTimeZoneId,
                year: 'numeric',
                month: '2-digit',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',
                hour12: false
            });

            const parts = formatter.formatToParts(new Date()).reduce(
                (acc, part) => {
                    acc[part.type] = part.value;
                    return acc;
                },
                {}
            );

            return new Date(
                Number(parts.year),
                Number(parts.month) - 1,
                Number(parts.day),
                Number(parts.hour),
                Number(parts.minute),
                Number(parts.second)
            );
        } catch (e) {
            return new Date();
        }
    }

    computeDurationHours(startDate, endDate) {
        if (!startDate || !endDate) {
            return 1;
        }
        const diffMs = endDate.getTime() - startDate.getTime();
        return Math.max(diffMs / (60 * 60 * 1000), 0.25);
    }

    formatTimeRange(startDate, endDate) {
        if (!startDate || !endDate) {
            return '';
        }

        const startText = startDate.toLocaleTimeString([], {
            hour: 'numeric',
            minute: '2-digit'
        });
        const endText = endDate.toLocaleTimeString([], {
            hour: 'numeric',
            minute: '2-digit'
        });

        return `${startText} – ${endText}`;
    }

    pad2(num) {
        return num.toString().padStart(2, '0');
    }

    formatPhoneDigits(digits) {
        if (!digits) {
            return null;
        }
        const onlyDigits = digits.replace(/\D/g, '');
        if (!onlyDigits) {
            return null;
        }

        if (onlyDigits.length === 10) {
            return (
                onlyDigits.slice(0, 3) +
                ' ' +
                onlyDigits.slice(3, 6) +
                ' ' +
                onlyDigits.slice(6)
            );
        }
        if (onlyDigits.length === 11 && onlyDigits.startsWith('1')) {
            return (
                '+1 ' +
                onlyDigits.slice(1, 4) +
                ' ' +
                onlyDigits.slice(4, 7) +
                ' ' +
                onlyDigits.slice(7)
            );
        }
        return onlyDigits;
    }

    parseReporterInfo(raw) {
        const result = {
            name: null,
            phone: null,
            phoneDisplay: null,
            phoneHref: null,
            email: null,
            emailHref: null
        };

        if (!raw) {
            return result;
        }

        const text = String(raw).trim();
        if (!text) {
            return result;
        }

        const emailMatch = text.match(
            /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i
        );
        if (emailMatch) {
            result.email = emailMatch[0];
            result.emailHref = `mailto:${encodeURIComponent(result.email)}`;
        }

        const digits = text.replace(/\D/g, '');
        if (digits && digits.length >= 7) {
            result.phone = digits;
            result.phoneDisplay = this.formatPhoneDigits(digits);
            result.phoneHref = `tel:${digits}`;
        }

        let nameSource = text;
        if (result.email) {
            nameSource = nameSource.replace(result.email, ' ');
        }

        nameSource = nameSource.replace(/[\d\-\+\(\)\.]/g, ' ');

        const name = nameSource.replace(/\s+/g, ' ').trim();
        result.name = name || null;

        return result;
    }

    buildCalendarModel() {
        if (!this.timelineStartDate && !this.weekStartDate) {
            this.centerCalendarOnToday();
            return;
        }

        this.showNowLine = false;
        this.nowLineStyle = '';

        const days = [];
        const dayMap = new Map();
        this.todayDayIndex = null;

        const startBase = this.isTimelineMode
            ? new Date(this.timelineStartDate || new Date())
            : new Date(this.weekStartDate || new Date());

        startBase.setHours(0, 0, 0, 0);
        const daysToShow = this.daysToShow;

        const totalHours = this.calendarEndHour - this.calendarStartHour;

        const nowLocal = this.getUserNow();

        for (let i = 0; i < daysToShow; i++) {
            const d = new Date(startBase);
            d.setDate(startBase.getDate() + i);

            const year = d.getFullYear();
            const month = d.getMonth() + 1;
            const dayNum = d.getDate();

            const key =
                year + '-' + this.pad2(month) + '-' + this.pad2(dayNum);

            const isToday =
                year === nowLocal.getFullYear() &&
                month === nowLocal.getMonth() + 1 &&
                dayNum === nowLocal.getDate();

            const weekdayLabel = d.toLocaleDateString([], {
                weekday: 'short'
            });
            const fullLabel = d.toLocaleDateString([], {
                weekday: 'short',
                month: 'short',
                day: 'numeric'
            });

            const day = {
                key,
                date: d,
                events: [],
                isToday,
                weekdayLabel,
                dayNumberLabel: dayNum,
                fullLabel,
                cssClassTimeline: isToday
                    ? 'sfs-calendar-day sfs-calendar-day_today'
                    : 'sfs-calendar-day',
                cssClassWeekCell: isToday
                    ? 'sfs-week-cell sfs-week-cell_today'
                    : 'sfs-week-cell'
            };

            if (isToday) {
                this.todayDayIndex = i;
            }

            days.push(day);
            dayMap.set(key, day);
        }

        const filteredAppointments = this.filterByWorkOrderNumber(
            this.appointments || []
        );

        filteredAppointments.forEach(appt => {
            if (!appt.schedStart) {
                return;
            }

            const startLocal = this.convertUtcToUserLocal(appt.schedStart);
            const endLocal = appt.schedEnd
                ? this.convertUtcToUserLocal(appt.schedEnd)
                : this.convertUtcToUserLocal(appt.schedStart);

            const year = startLocal.getFullYear();
            const month = startLocal.getMonth() + 1;
            const dayNum = startLocal.getDate();

            const dayKey =
                year + '-' + this.pad2(month) + '-' + this.pad2(dayNum);

            const day = dayMap.get(dayKey);
            if (!day) {
                return;
            }

            const eventKey = `${appt.appointmentId}-${dayKey}`;

            let startHour =
                startLocal.getHours() + startLocal.getMinutes() / 60;
            let endHour =
                endLocal.getHours() + endLocal.getMinutes() / 60;

            startHour = Math.max(startHour, this.calendarStartHour);
            endHour = Math.min(endHour, this.calendarEndHour);

            if (endHour <= startHour) {
                endHour = startHour + 0.25;
            }

            const topPct =
                ((startHour - this.calendarStartHour) / totalHours) * 100;
            const heightPct =
                ((endHour - startHour) / totalHours) * 100;

            const timeLabel = startLocal.toLocaleTimeString([], {
                hour: 'numeric',
                minute: '2-digit'
            });

            const displaySubject = this.getServiceAppointmentDisplayTitle(appt);

            const typeMeta = this.getEventTypeMeta
                ? this.getEventTypeMeta(appt.workTypeName)
                : { className: '', symbol: '' };
            const typeClass = typeMeta.className;
            const baseTimelineClass = `sfs-calendar-event ${typeClass}`.trim();
            const baseWeekClass = `sfs-week-event-box ${typeClass}`.trim();

            day.events.push({
                id: appt.appointmentId,
                key: eventKey,
                style: `top:${topPct}%;height:${heightPct}%;`,
                subject:
                    appt.serviceAppointmentSubject ||
                    appt.description ||
                    appt.workOrderSubject,
                workOrderNumber: appt.workOrderNumber,
                workTypeName: appt.workTypeName,
                timeLabel,
                isCrewAssignment: appt.isCrewAssignment,
                isMyAssignment: appt.isMyAssignment,
                isAbsence: false,
                workTypeSymbol: typeMeta.symbol,
                kind: 'appointment',
                className: baseTimelineClass,
                classNameWeek: baseWeekClass,
                baseClassTimeline: baseTimelineClass,
                baseClassWeek: baseWeekClass
            });
        });

        this.absences.forEach(abs => {
            if (!abs.start || !abs.endTime) {
                return;
            }

            const startLocal = this.convertUtcToUserLocal(abs.start);
            const endLocal = this.convertUtcToUserLocal(abs.endTime);

            const startDay = new Date(startLocal);
            startDay.setHours(0, 0, 0, 0);
            const endDay = new Date(endLocal);
            endDay.setHours(0, 0, 0, 0);

            const baseTimelineClass = 'sfs-calendar-event sfs-calendar-event_absence';
            const baseWeekClass = 'sfs-week-event-box sfs-week-event-box_absence';

            for (
                let cursor = new Date(startDay);
                cursor.getTime() <= endDay.getTime();
                cursor.setDate(cursor.getDate() + 1)
            ) {
                const year = cursor.getFullYear();
                const month = cursor.getMonth() + 1;
                const dayNum = cursor.getDate();
                const dayKey =
                    year + '-' + this.pad2(month) + '-' + this.pad2(dayNum);
                const day = dayMap.get(dayKey);
                if (!day) {
                    continue;
                }

                const dayStart = new Date(cursor);
                const dayEnd = new Date(cursor);
                dayEnd.setHours(23, 59, 59, 999);

                const segmentStart =
                    startLocal.getTime() > dayStart.getTime()
                        ? startLocal
                        : dayStart;
                const segmentEnd =
                    endLocal.getTime() < dayEnd.getTime() ? endLocal : dayEnd;

                let startHour =
                    segmentStart.getHours() + segmentStart.getMinutes() / 60;
                let endHour = segmentEnd.getHours() + segmentEnd.getMinutes() / 60;

                startHour = Math.max(startHour, this.calendarStartHour);
                endHour = Math.min(endHour, this.calendarEndHour);

                if (endHour <= startHour) {
                    endHour = startHour + 0.25;
                }

                const topPct =
                    ((startHour - this.calendarStartHour) / totalHours) * 100;
                const heightPct = ((endHour - startHour) / totalHours) * 100;

                const timeLabel = this.formatTimeRange(segmentStart, segmentEnd);
                const key = `${abs.absenceId}-${dayKey}`;

                day.events.push({
                    id: abs.absenceId,
                    key,
                    style: `top:${topPct}%;height:${heightPct}%;`,
                    subject: abs.subject || 'Absence',
                    workOrderNumber: null,
                    workTypeName: null,
                    timeLabel,
                    isCrewAssignment: false,
                    isMyAssignment: false,
                    isAbsence: true,
                    kind: 'absence',
                    className: baseTimelineClass,
                    classNameWeek: baseWeekClass,
                    baseClassTimeline: baseTimelineClass,
                    baseClassWeek: baseWeekClass
                });
            }
        });

        if (this.isTimelineMode) {
            this.showNowLine = true;
        }

        this.calendarDays = days;
        this.updateSelectedEventStyles();
        this.scheduleNowLinePositionUpdate();
    }

    toggleFilters() {
        this.filtersOpen = !this.filtersOpen;
    }

    toggleActionStatusFocus() {
        this.isActionStatusFocusEnabled = !this.isActionStatusFocusEnabled;
        this.ensureActionStatusFocusMode();
        this.collapsedDayGroups = {};
    }

    ensureActionStatusFocusMode() {
        if (!this.isActionStatusFocusEnabled) {
            return;
        }

        const actionOptions = this.getActionStatusModeOptions();
        if (!actionOptions.length) {
            return;
        }

        const hasActiveActionMode =
            ACTION_STATUS_FILTER_MODES.includes(this.listMode) &&
            this.getListModeCountForPrimaryTab(
                this.listMode,
                this.listModePrimaryTab
            ) > 0;

        if (hasActiveActionMode) {
            return;
        }

        const fallbackMode = actionOptions[0]?.value;
        if (fallbackMode) {
            this.listMode = fallbackMode;
        }
    }

    get searchFieldGuideToggleLabel() {
        return this.showSearchFieldGuide
            ? 'Hide searchable fields'
            : 'See searchable fields';
    }

    toggleSearchFieldGuide() {
        this.showSearchFieldGuide = !this.showSearchFieldGuide;
    }

    handleWorkOrderNumberFilterChange(event) {
        this.hasInteractedWithWorkOrderNumberFilter = true;
        const value = event.detail.value;
        clearTimeout(this._workOrderFilterDebounce);
        this._workOrderFilterDebounce = setTimeout(() => {
            this.workOrderNumberFilter = value;
            this.refreshCalendarForFilters();
        }, 300);
    }

    clearWorkOrderNumberFilter() {
        this.hasInteractedWithWorkOrderNumberFilter = true;
        this.workOrderNumberFilter = '';
        this.refreshCalendarForFilters();
    }

    refreshCalendarForFilters() {
        if (this.isCalendarTabActive) {
            this.buildCalendarModel();
        }
    }

    scheduleNowLinePositionUpdate() {
        if (
            !this.hasWindow ||
            !this.isCalendarTabActive ||
            !this.isTimelineMode ||
            typeof window.requestAnimationFrame !== 'function' ||
            typeof window.cancelAnimationFrame !== 'function'
        ) {
            return;
        }

        if (this._nowLineFrame) {
            window.cancelAnimationFrame(this._nowLineFrame);
        }

        this._nowLineFrame = window.requestAnimationFrame(() => {
            this._nowLineFrame = null;
            this.updateNowLinePosition();
        });
    }

    updateNowLinePosition() {
        if (!this.isTimelineMode) {
            this.showNowLine = false;
            this.nowLineStyle = '';
            return;
        }

        const calendarEl = this.template.querySelector('.sfs-calendar');
        const dayBodyEl = this.template.querySelector('.sfs-calendar-day-body');

        if (!calendarEl || !dayBodyEl) {
            return;
        }

        const calendarRect = calendarEl.getBoundingClientRect();
        const bodyRect = dayBodyEl.getBoundingClientRect();

        const totalHours = this.calendarEndHour - this.calendarStartHour;
        const nowLocal = this.getUserNow();
        const nowHourFraction =
            nowLocal.getHours() + nowLocal.getMinutes() / 60;

        const clampedHour = Math.min(
            Math.max(nowHourFraction, this.calendarStartHour),
            this.calendarEndHour
        );

        const relativePct =
            (clampedHour - this.calendarStartHour) / totalHours;

        const offsetTop = bodyRect.top - calendarRect.top;
        const topPx = offsetTop + relativePct * bodyRect.height;

        const style = `top:${topPx}px;`;

        if (!this.showNowLine || this.nowLineStyle !== style) {
            this.showNowLine = true;
            this.nowLineStyle = style;
        }
    }

    updateSelectedEventStyles() {
        const selectedIds = [];
        if (this.selectedAppointment) {
            selectedIds.push(this.selectedAppointment.appointmentId);
        }

        if (this.selectedAbsence) {
            selectedIds.push(this.selectedAbsence.absenceId);
        }

        const draggingId = this.dragMode ? this.draggingEventId : null;

        const updatedDays = this.calendarDays.map(day => {
            const newEvents = day.events.map(evt => {
                const baseTimeline =
                    evt.baseClassTimeline || 'sfs-calendar-event';
                const baseWeek =
                    evt.baseClassWeek || 'sfs-week-event-box';

                const isSelected =
                    selectedIds.length > 0 && selectedIds.includes(evt.id);
                const isDragging = draggingId && evt.id === draggingId;

                let classTimeline = baseTimeline;
                let classWeek = baseWeek;

                if (isSelected) {
                    classTimeline += ' sfs-calendar-event_selected';
                    classWeek += ' sfs-week-event-box_selected';
                }

                if (isDragging) {
                    classTimeline += ' sfs-calendar-event_dragging';
                    classWeek += ' sfs-week-event-box_dragging';
                }

                return {
                    ...evt,
                    className: classTimeline,
                    classNameWeek: classWeek
                };
            });

            return { ...day, events: newEvents };
        });

        this.calendarDays = updatedDays;
    }


    // ======= LIST TAB HANDLERS =======

    handleRecentModeTabClick(event) {
        const tabValue = event?.currentTarget?.dataset?.recentModeTab;
        if (!tabValue || tabValue === this.recentMode) {
            return;
        }

        this.recentMode = tabValue;
    }

    handleHistoryModeTabChange(event) {
        const tabValue = event?.currentTarget?.dataset?.historyModeTab;
        if (!tabValue || tabValue === this.historyMode) {
            return;
        }

        this.historyMode = tabValue;
    }

    handleListModeChange(event) {
        const mode =
            event?.detail?.value ||
            event?.currentTarget?.dataset?.mode ||
            event?.target?.dataset?.mode;
        this.setListMode(mode);
    }

    handleListModePrimaryTabChange(event) {
        const tabValue = event?.currentTarget?.dataset?.listModeTab;
        if (!tabValue) {
            return;
        }

        if (tabValue === this.listModePrimaryTab) {
            this.listModePrimaryTab = 'all';
            this.collapsedDayGroups = {};
            this.resetListPagination();
            this.syncListModeWithOptions();
            return;
        }

        this.listModePrimaryTab = tabValue;
        this.listMode = tabValue === 'scheduled' ? 'my' : 'unscheduled';
        this.collapsedDayGroups = {};
        this.resetListPagination();
        this.syncListModeWithOptions();
    }

    handleOpportunityTypeChange(event) {
        const typeValue = event?.currentTarget?.dataset?.opportunityType;
        if (!typeValue || typeValue === this.listOpportunityType) {
            return;
        }

        this.listOpportunityType = typeValue;
        this.resetListPagination();
        this.syncListModeWithOptions();
    }

    handlePreventativeMaintenanceTabChange(event) {
        const tabValue =
            event?.currentTarget?.dataset?.preventativeMaintenanceTab;
        if (!tabValue || tabValue === this.preventativeMaintenanceTab) {
            return;
        }

        this.preventativeMaintenanceTab = tabValue;
        this.collapsedDayGroups = {};
    }

    handlePreventativeMaintenanceUnscheduledTabChange(event) {
        const tabValue =
            event?.currentTarget?.dataset?.preventativeMaintenanceUnscheduledTab;
        if (!tabValue || tabValue === this.preventativeMaintenanceUnscheduledTab) {
            return;
        }

        this.preventativeMaintenanceUnscheduledTab = tabValue;
        this.collapsedDayGroups = {};
    }

    setListMode(mode) {
        if (!mode) {
            return;
        }

        const fallbackMode =
            this.listModePrimaryTab === 'scheduled' ? 'my' : 'unscheduled';

        if (this.listModePrimaryTab !== 'all' && mode === 'my') {
            this.listModePrimaryTab = 'scheduled';
        } else if (this.listModePrimaryTab !== 'all' && mode === 'unscheduled') {
            this.listModePrimaryTab = 'unscheduled';
        }

        if (mode === this.listMode) {
            if (mode !== fallbackMode) {
                this.listMode = fallbackMode;
                this.collapsedDayGroups = {};
                this.resetListPagination();
            }
            return;
        }

        this.listMode = mode;
        this.collapsedDayGroups = {};
        this.resetListPagination();
    }

    handleToggleQuoteLineItems(event) {
        const cardId =
            event?.detail?.cardId ??
            event?.currentTarget?.dataset?.cardId;

        if (!cardId) {
            return;
        }

        const isExpanded = Boolean(this.quoteLineItemsExpanded[cardId]);
        this.quoteLineItemsExpanded = {
            ...this.quoteLineItemsExpanded,
            [cardId]: !isExpanded
        };
    }

    handleToggleJourney(event) {
        const cardId = event?.currentTarget?.dataset?.cardId;

        if (!cardId) {
            return;
        }

        const isExpanded = Boolean(this.journeyExpanded[cardId]);
        this.journeyExpanded = {
            ...this.journeyExpanded,
            [cardId]: !isExpanded
        };

        if (this.selectedAppointment && this.selectedAppointment.cardId === cardId) {
            const journeyExpanded = !isExpanded;
            this.selectedAppointment = {
                ...this.selectedAppointment,
                journeyExpanded,
                journeyToggleLabel: journeyExpanded ? 'Hide checklist' : 'View checklist',
                journeyToggleTitle: journeyExpanded ? 'Hide full checklist' : 'View full checklist',
                journeyToggleIcon: journeyExpanded
                    ? 'utility:chevrondown'
                    : 'utility:chevronright'
            };
        }
    }

    handleVisitSelectionChange(event) {
        const workOrderId =
            event?.detail?.workOrderId ??
            event?.currentTarget?.dataset?.workOrderId;
        const rawValue =
            event?.detail?.value !== undefined
                ? event.detail.value
                : event?.target?.value;
        const selectedValue = Number.parseInt(rawValue, 10);

        if (!workOrderId || !Number.isInteger(selectedValue)) {
            return;
        }

        this.selectedVisitByWorkOrder = {
            ...this.selectedVisitByWorkOrder,
            [workOrderId]: selectedValue
        };

        this.syncListModeWithOptions();
    }

    handleQuoteAttachmentClick(event) {
        event.preventDefault?.();

        const cardId =
            event.detail?.id ??
            event.currentTarget?.dataset?.id;
        if (!cardId) {
            return;
        }

        const appt = this.findAppointmentByCardId(cardId);

        if (!appt || !appt.workOrderId) {
            this.showToast(
                'Work order unavailable',
                'Unable to open the files for this work order.',
                'warning'
            );
            return;
        }

        const filesDeepLink = `com.salesforce.fieldservice://v1/sObject/${appt.workOrderId}/related`;

        try {
            const navPromise = this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: { url: filesDeepLink }
            });

            if (navPromise && typeof navPromise.catch === 'function') {
                navPromise.catch(error => {
                    const message =
                        (error &&
                            (error.message ||
                                (error.body && error.body.message))) ||
                        'Unable to open the work order files.';
                    this.showToast('Navigation failed', message, 'error');
                });
            }
        } catch (err) {
            const message =
                (err && (err.message || (err.body && err.body.message))) ||
                'Unable to open the work order files.';
            this.showToast('Navigation failed', message, 'error');
        }
    }

    handleMarkQuoteSent(event) {
        const workOrderId = event.detail?.woid ?? event.target?.dataset?.woid;
        this._markWorkOrderStatus(workOrderId, markWorkOrderQuoteSent, {
            successBody: 'Work order marked as Quote Sent.',
            debugNote: 'Error calling markWorkOrderQuoteSent'
        });
    }

    handleMarkRepairSent(event) {
        const workOrderId = event.detail?.woid ?? event.target?.dataset?.woid;
        this._markWorkOrderStatus(workOrderId, markWorkOrderPendingApproval, {
            successBody: 'Work order marked as Repair Sent.',
            debugNote: 'Error calling markWorkOrderPendingApproval'
        });
    }

    handleMarkPoAttached(event) {
        const workOrderId = event.detail?.woid ?? event.target?.dataset?.woid;
        const record = this.findRecordByWorkOrderId(workOrderId);
        if (record && !this.hasCompleteShippingAddress(record)) {
            this.showToast(
                'Add shipping address',
                'Add a complete shipping address before marking Ready to Ship.',
                'warning'
            );
            return;
        }
        this._markWorkOrderStatus(workOrderId, markWorkOrderPoAttached, {
            successBody: 'Work order marked as Ready to Ship.',
            debugNote: 'Error calling markWorkOrderPoAttached'
        });
    }

    handleCancelSale(event) {
        const workOrderId = event.detail?.woid ?? event.target?.dataset?.woid;
        this.openCancelSaleModal(workOrderId);
    }

    openCancelSaleModal(workOrderId) {
        if (!workOrderId) {
            return;
        }
        this.cancelSaleWorkOrderId = workOrderId;
        this.cancelSaleNotes = '';
        this.isCancelSaleModalOpen = true;
    }

    closeCancelSaleModal() {
        this.isCancelSaleModalOpen = false;
        this.cancelSaleNotes = '';
        this.cancelSaleWorkOrderId = null;
    }

    handleCancelSaleNotesChange(event) {
        this.cancelSaleNotes = event.target.value;
    }

    get cancelSaleSubmitDisabled() {
        return this.isLoading || !this.cancelSaleNotes || !this.cancelSaleNotes.trim();
    }

    submitCancelSale() {
        if (!this.cancelSaleWorkOrderId || !this.cancelSaleNotes) {
            return;
        }

        if (this.isOffline) {
            this.showToast(
                'Offline',
                'You must be online to cancel a sale.',
                'warning'
            );
            return;
        }

        this.isLoading = true;

        markWorkOrderCancelSale({
            workOrderId: this.cancelSaleWorkOrderId,
            notes: this.cancelSaleNotes
        })
            .then(() => {
                this.showToast(
                    'Sale canceled',
                    'The work order was marked as Cancel Sale and the note was saved.',
                    'success'
                );
                this.closeCancelSaleModal();
                return this.loadAppointments({ preserveScroll: true });
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.debugInfo = { note: 'Error calling markWorkOrderCancelSale', errorMessage: message };
                this.showToast('Error canceling sale', message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    markWaitingForPo(workOrderId) {
        this._markWorkOrderStatus(workOrderId, markWorkOrderWaitingForPo, {
            successTitle: 'Updated',
            successBody: 'Work order marked as Waiting for PO.',
            errorTitle: 'Error updating work order',
            debugNote: 'Error calling markWorkOrderWaitingForPo'
        });
    }

    closePoRequiredModal() {
        this.isPoRequiredModalOpen = false;
        this.poRequiredWorkOrderId = null;
        this.poRequiredActionLabel = '';
    }

    handlePoRequiredEdit() {
        if (!this.poRequiredWorkOrderId) {
            return;
        }

        const targetId = this.poRequiredWorkOrderId;
        this.closePoRequiredModal();
        this.startPoNumberEdit(targetId);
    }

    handlePoNumberEdit(event) {
        const workOrderId =
            event.detail?.woid ??
            event.currentTarget?.dataset?.woid;
        if (!workOrderId) {
            return;
        }

        this.startPoNumberEdit(workOrderId);
    }

    handlePoNumberCancel(event) {
        const workOrderId =
            (event?.detail?.woid ??
            event?.currentTarget?.dataset?.woid) ||
            this.poNumberModalWorkOrderId;
        this.cancelPoNumberEdit(workOrderId);
    }

    handlePoNumberDraftChange(event) {
        const value = event.detail?.value;
        if (this.isPoNumberModalOpen) {
            if (this.poNumberModalValue === value && this._poNumberModalPending === null) {
                return;
            }
            this._poNumberModalPending = value;
            clearTimeout(this._poNumberModalDebounceTimer);
            this._poNumberModalDebounceTimer = setTimeout(() => {
                this.poNumberModalValue = this._poNumberModalPending;
                this._poNumberModalPending = null;
            }, 150);
            return;
        }

        const workOrderId =
            event.detail?.woid ??
            event.currentTarget?.dataset?.woid;
        if (!workOrderId) {
            return;
        }

        this._poNumberInlinePending = { workOrderId, value };
        clearTimeout(this._poNumberInlineDebounceTimer);
        this._poNumberInlineDebounceTimer = setTimeout(() => {
            if (this._poNumberInlinePending) {
                this.updateRecordsByWorkOrderId(this._poNumberInlinePending.workOrderId, item => ({
                    ...item,
                    poNumberDraft: this._poNumberInlinePending.value,
                    isEditingPoNumber: true
                }));
                this._poNumberInlinePending = null;
            }
        }, 150);
    }

    _flushPoNumberModalChanges() {
        if (this._poNumberModalPending === null) return;
        clearTimeout(this._poNumberModalDebounceTimer);
        this.poNumberModalValue = this._poNumberModalPending;
        this._poNumberModalPending = null;
    }

    _flushPoNumberInlineChanges() {
        if (!this._poNumberInlinePending) return;
        clearTimeout(this._poNumberInlineDebounceTimer);
        this.updateRecordsByWorkOrderId(this._poNumberInlinePending.workOrderId, item => ({
            ...item,
            poNumberDraft: this._poNumberInlinePending.value,
            isEditingPoNumber: true
        }));
        this._poNumberInlinePending = null;
    }

    handlePoNumberKeydown(event) {
        const key = event.detail?.key ?? event.key;
        if (key !== 'Enter') {
            return;
        }

        event.preventDefault?.();
        const workOrderId =
            (event.detail?.woid ??
            event.currentTarget?.dataset?.woid) ||
            this.poNumberModalWorkOrderId;
        if (!workOrderId) {
            return;
        }

        this.savePoNumber(workOrderId);
    }

    handlePoNumberSave(event) {
        const workOrderId =
            (event?.detail?.woid ??
            event?.currentTarget?.dataset?.woid) ||
            this.poNumberModalWorkOrderId;
        if (!workOrderId) {
            return;
        }

        this.savePoNumber(workOrderId);
    }

    savePoNumber(workOrderId) {
        if (this.isPoNumberModalOpen && this.poNumberModalWorkOrderId === workOrderId) {
            this._flushPoNumberModalChanges();
        } else {
            this._flushPoNumberInlineChanges();
        }

        const record = this.findRecordByWorkOrderId(workOrderId);
        if (!record) {
            return;
        }

        const draft = this.normalizePoNumberValue(
            this.isPoNumberModalOpen &&
                this.poNumberModalWorkOrderId === workOrderId
                ? this.poNumberModalValue
                : record.poNumberDraft
        );
        if (!draft) {
            this.showToast(
                'PO Number required',
                'Enter a PO number before saving.',
                'warning'
            );
            return;
        }

        this.checkOnline();
        if (this.isOffline) {
            this.showToast(
                'Offline',
                'You must be online to update the PO number.',
                'warning'
            );
            return;
        }

        this.poNumberSaving = true;

        updateWorkOrderPoNumber({ workOrderId, poNumber: draft })
            .then(result => {
                const updatedPoNumber = result?.poNumber || draft;
                this.applyPoNumberUpdate(workOrderId, updatedPoNumber);
                if (this.poNumberModalWorkOrderId === workOrderId) {
                    this.closePoNumberModal();
                }
                if (this.poRequiredWorkOrderId === workOrderId) {
                    this.closePoRequiredModal();
                }
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.debugInfo = {
                    note: 'Error calling updateWorkOrderPoNumber',
                    errorMessage: message
                };
                this.showToast('Error updating PO Number', message, 'error');
            })
            .finally(() => {
                this.poNumberSaving = false;
            });
    }

    handleServiceSiteEdit(event) {
        const workOrderId =
            event.detail?.woid ??
            event.currentTarget?.dataset?.woid;
        if (!workOrderId) {
            return;
        }
        this.startServiceSiteEdit(workOrderId);
    }

    handleServiceSiteCancel() {
        this.closeServiceSiteModal();
    }

    handleServiceSiteDraftChange(event) {
        const value = event.detail?.value;
        if (this._serviceSiteModalPending === value && this._serviceSiteModalPending === null) {
            return;
        }
        this._serviceSiteModalPending = value;
        clearTimeout(this._serviceSiteModalDebounceTimer);
        this._serviceSiteModalDebounceTimer = setTimeout(() => {
            this.serviceSiteModalValue = this._serviceSiteModalPending;
            this._serviceSiteModalPending = null;
        }, 150);
    }

    handleServiceSiteKeydown(event) {
        const key = event.detail?.key ?? event.key;
        if (key !== 'Enter') {
            return;
        }
        event.preventDefault?.();
        if (this.serviceSiteModalWorkOrderId) {
            this.saveServiceSiteName(this.serviceSiteModalWorkOrderId);
        }
    }

    handleServiceSiteSave() {
        if (this.serviceSiteModalWorkOrderId) {
            this.saveServiceSiteName(this.serviceSiteModalWorkOrderId);
        }
    }

    handleApproveRepair(event) {
        const workOrderId = event.detail?.woid ?? event.target?.dataset?.woid;
        if (!workOrderId) { return; }
        this.repairApprovalWorkOrderId = workOrderId;
        this.isRepairApprovalModalOpen = true;
    }

    closeRepairApprovalModal() {
        this.isRepairApprovalModalOpen = false;
        this.repairApprovalWorkOrderId = null;
    }

    _submitRepairApproved(notes) {
        const workOrderId = this.repairApprovalWorkOrderId;
        this.closeRepairApprovalModal();
        if (!workOrderId) { return; }
        this.checkOnline();
        if (this.isOffline) {
            this.showToast('Offline', 'You must be online to update the work order status.', 'warning');
            return;
        }
        this.isLoading = true;
        markWorkOrderRepairApproved({ workOrderId, notes })
            .then(() => {
                this.showToast('Status updated', 'Work order marked as Repair Approved.', 'success');
                return this.loadAppointments({ preserveScroll: true });
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.debugInfo = { note: 'Error calling markWorkOrderRepairApproved', errorMessage: message };
                this.showToast('Error updating status', message, 'error');
            })
            .finally(() => { this.isLoading = false; });
    }

    submitApproveRecommendedRepair() {
        this._submitRepairApproved('Approved recommended repair');
    }

    submitApproveRequiredRepairOnly() {
        this._submitRepairApproved('Approved required repair only');
    }

    handleApproveExchange(event) {
        const workOrderId = event.detail?.woid ?? event.target?.dataset?.woid;
        this._markWorkOrderStatus(workOrderId, markWorkOrderExchangeApproved, {
            successBody: 'Work order marked as Exchange Approved.',
            debugNote: 'Error calling markWorkOrderExchangeApproved'
        });
    }

    handleDeclineRepair(event) {
        const workOrderId = event.detail?.woid ?? event.target?.dataset?.woid;
        const record = this.findRecordByWorkOrderId(workOrderId);
        this.repairDeclineConfirmWorkOrderId = workOrderId;
        this.repairDeclineConfirmRecord = record;
        this.isRepairDeclineConfirmModalOpen = true;
    }

    closeRepairDeclineConfirmModal() {
        this.isRepairDeclineConfirmModalOpen = false;
        this.repairDeclineConfirmWorkOrderId = null;
        this.repairDeclineConfirmRecord = null;
    }

    handleConfirmDeclineRepair() {
        const workOrderId = this.repairDeclineConfirmWorkOrderId;
        this.closeRepairDeclineConfirmModal();
        this._markWorkOrderStatus(workOrderId, markWorkOrderRepairDeclined, {
            successBody: 'Work order marked as Repair Declined.',
            debugNote: 'Error calling markWorkOrderRepairDeclined'
        });
    }

    handleEditShippingFromDeclineModal() {
        const workOrderId = this.repairDeclineConfirmWorkOrderId;
        const record = this.repairDeclineConfirmRecord;
        if (!record) return;

        const rawState = this.normalizeAddressValue(record?.shippingState);
        const initialState = rawState.length > 2 ? '' : this.normalizeStateInput(rawState);

        this.shippingAddressForm = {
            attn: this.normalizeAddressValue(record?.shippingAttn),
            shippingSiteName: this.normalizeAddressValue(record?.shippingSiteName || record?.serviceSiteName),
            street: this.normalizeAddressValue(record?.shippingStreet),
            city: this.normalizeAddressValue(record?.shippingCity),
            state: initialState,
            country: this.normalizeAddressValue(record?.shippingCountry) || 'United States',
            postalCode: this.normalizeAddressValue(record?.shippingPostalCode)
        };

        this.shippingAddressModalWorkOrderId = workOrderId;
        this.shippingAddressModalAppointmentId = record?.appointmentId || null;
        this.shippingAddressModalCardId = null;
        this.shippingAddressSaving = false;
        this.shippingAddressSelection = '';
        this.repairDeclineShippingEditPending = true;
        this.isRepairDeclineConfirmModalOpen = false;
        this.isShippingAddressModalOpen = true;

        this.loadUserShippingAddresses().finally(() => {
            if (this.shippingAddressOptions.length > 0) {
                this.shippingAddressMode = 'saved';
            } else {
                this.shippingAddressMode = 'manual';
            }
        });

        this.prefillShippingAddressState(rawState, null);
    }

    handleConfirmShipping(event) {
        const workOrderId = event.detail?.woid ?? event.target?.dataset?.woid;
        const record = this.findRecordByWorkOrderId(workOrderId);
        if (record && !this.hasCompleteShippingAddress(record)) {
            this.showToast(
                'Add shipping address',
                'Add a complete shipping address before confirming shipping.',
                'warning'
            );
            return;
        }
        this._markWorkOrderStatus(workOrderId, markWorkOrderConfirmedShipping, {
            successBody: 'Work order marked as Confirmed Shipping.',
            debugNote: 'Error calling markWorkOrderConfirmedShipping'
        });
    }

    handleCrewMemberChange(event) {
        // From child component, detail has { id, value }.
        // From direct lightning-combobox, event.target.dataset.id + event.detail.value.
        const id =
            event.detail?.id ??
            event.target?.dataset?.id;
        const value =
            event.detail?.value;

        this.appointments = this.appointments.map(appt => {
            if (appt.appointmentId === id) {
                return {
                    ...appt,
                    selectedCrewMemberId: value,
                    disableAssignTech: !value
                };
            }
            return appt;
        });

        if (
            this.selectedAppointment &&
            this.selectedAppointment.appointmentId === id
        ) {
            this.selectedAppointment = {
                ...this.selectedAppointment,
                selectedCrewMemberId: value,
                disableAssignTech: !value
            };
        }
    }

    handleAssignToCrewMember(event) {
        const id =
            event.detail?.id ??
            event.target?.dataset?.id;
        const appt = this.appointments.find(a => a.appointmentId === id);

        if (!appt || !appt.selectedCrewMemberId) {
            this.showToast(
                'Pick a technician',
                'Select a crew member before assigning.',
                'warning'
            );
            return;
        }

        this.checkOnline();
        if (this.isOffline) {
            this.showToast(
                'Offline',
                'You must be online to assign an appointment.',
                'warning'
            );
            return;
        }

        this.isLoading = true;

        assignCrewAppointment({
            serviceAppointmentId: id,
            serviceResourceId: appt.selectedCrewMemberId
        })
            .then(() => {
                this.showToast(
                    'Appointment reassigned',
                    'The appointment has been assigned to the selected technician.',
                    'success'
                );
                this.loadAppointments({ preserveScroll: true });
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.debugInfo = {
                    note: 'Error calling assignCrewAppointment',
                    errorMessage: message
                };
                this.showToast('Error assigning appointment', message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleToggleListDetails(event) {
        const id =
            event.detail?.id ??
            event.currentTarget?.dataset?.id;
        const toggleExpanded = appt =>
            appt.cardId === id
                ? {
                    ...appt,
                    isExpanded: !appt.isExpanded
                }
                : appt;
        this.appointments = this.appointments.map(toggleExpanded);
        this.unscheduledWorkOrders = (this.unscheduledWorkOrders || []).map(
            toggleExpanded
        );
    }

    handleToggleGroup(event) {
        const { groupKey } = event.currentTarget.dataset;

        if (!groupKey) {
            return;
        }

        this.collapsedDayGroups = {
            ...this.collapsedDayGroups,
            [groupKey]: !this.collapsedDayGroups[groupKey]
        };
    }

    handleCollapseAllGroups() {
        const groups = this.appointmentGroups || [];
        if (!groups.length) {
            return;
        }

        const collapsed = {};
        groups.forEach(group => {
            collapsed[group.key] = true;
        });

        this.collapsedDayGroups = collapsed;
    }

    handleRefresh() {
        this.checkOnline();
        if (this.isOffline) {
            this.showToast(
                'Offline',
                'You must be online to refresh data.',
                'warning'
            );
            return;
        }

        if (this.isHistoryTabActive) {
            this.handleLoadHistory();
            return;
        }

        if (this.isRmaTabActive) {
            this.rmaLoaded = false;
            this.loadRmas();
            return;
        }

        this.loadAppointments({ preserveScroll: true });
    }

    async handleLaunchQuickQuoteFlow() {
        this.checkOnline();
        if (this.isOffline) {
            this.showToast(
                'Offline',
                'You must be online to launch the Quick Quote flow.',
                'warning'
            );
            return;
        }

        const quickQuoteDeepLink =
            'com.salesforce.fieldservice://v1/sObject/a4URo000000kypBMAQ/flow/FSL_Action_Quick_Quote_2';

        try {
            this.navigateToUrl(quickQuoteDeepLink);
        } catch (error) {
            console.error('Unable to open Quick Quote deep link', error);

            this.showToast(
                'Quick Quote unavailable',
                'We were unable to open the Quick Quote flow. Please try again.',
                'error'
            );
        }
    }

    getWorkOrderIdFromItem(item) {
        if (!item) {
            return null;
        }

        return item.workOrderId || null;
    }

    findFirstWorkOrderId(items) {
        if (!items || !Array.isArray(items)) {
            return null;
        }

        const match = items.find(item => this.getWorkOrderIdFromItem(item));

        return match ? this.getWorkOrderIdFromItem(match) : null;
    }

    buildFlowPageReference(flowApiName, workOrderId) {
        return {
            type: 'standard__flow',
            attributes: {
                flowApiName
            },
            state: workOrderId
                ? {
                      recordId: workOrderId
                  }
                : {}
        };
    }

    navigateToUrl(url) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url }
        });
    }

    handleReschedule(event) {
        const id = event.target.dataset.id;
        const appt = this.appointments.find(a => a.appointmentId === id);

        if (!appt || !appt.newStart) {
            this.showToast(
                'Pick a date and time',
                'Select a new start date and time before rescheduling.',
                'warning'
            );
            return;
        }

        if (!this.hasScheduleAddress(appt)) {
            this.showAddressRequiredHelp(id);
            return;
        }

        this.rescheduleExistingAppointment(id, appt.newStart);
    }

    handleScheduleActionClick(event) {
        // When fired from child, detail contains isBlocked, id, and targetIsCurrentTarget
        const isBlocked =
            event?.detail?.isBlocked ??
            (event?.currentTarget?.dataset?.blocked === 'true' ||
            event?.currentTarget?.dataset?.blocked === true);

        const targetIsCurrentTarget =
            event?.detail?.targetIsCurrentTarget ??
            (event.target === event.currentTarget);

        if (!isBlocked || !targetIsCurrentTarget) {
            return;
        }

        const cardId =
            (event?.detail?.id ??
            event?.currentTarget?.dataset?.id) ||
            null;
        this.showAddressRequiredHelp(cardId);
        event.stopPropagation();
        event.preventDefault();
    }

    handleScheduleOnCalendar(event) {
        const cardId =
            event?.detail?.id ??
            (event && event.currentTarget && event.currentTarget.dataset
                ? event.currentTarget.dataset.id
                : null);

        if (!cardId) {
            return;
        }

        const target = this.findAppointmentByCardId(cardId);

        if (!target) {
            return;
        }

        if (!this.hasScheduleAddress(target)) {
            this.showAddressRequiredHelp(cardId);
            return;
        }

        this.schedulePreviewCardId = target.cardId || null;
        this.schedulePreviewListMode = this.listMode;
        this.isAwaitingScheduleConfirmation = false;
        this.pendingSchedulePlacement = null;
        this.dragRequiresExplicitConfirmation = true;

        this.startScheduleOnCalendar(target);
    }

    handleToggleQuickSchedulePanel(event) {
        const cardId =
            event?.detail?.id ??
            event?.currentTarget?.dataset?.id;

        if (!cardId) {
            return;
        }

        const appt = this.findAppointmentByCardId(cardId);

        if (!appt) {
            this.showToast(
                'Unable to schedule',
                'Could not load this work order. Refresh and try again.',
                'warning'
            );
            return;
        }

        if (!this.hasScheduleAddress(appt)) {
            this.showAddressRequiredHelp(cardId);
            return;
        }

        const isExpanded = Boolean(this.quickScheduleExpanded[cardId]);
        const nextExpanded = !isExpanded;
        this.quickScheduleExpanded = {
            ...this.quickScheduleExpanded,
            [cardId]: nextExpanded
        };

        if (nextExpanded) {
            this.ensureQuickScheduleSelection(cardId, appt);
        }
    }

    handleQuickScheduleChange(event) {
        const cardId =
            event.detail?.id ??
            event.target?.dataset?.id;
        const value =
            event.detail?.value ??
            event.target?.value;

        if (!cardId) {
            return;
        }

        this.quickScheduleSelections = {
            ...this.quickScheduleSelections,
            [cardId]: value
        };
    }

    handleQuickSchedule(event) {
        const cardId =
            event?.detail?.id ??
            (event && event.currentTarget && event.currentTarget.dataset
                ? event.currentTarget.dataset.id
                : null);

        if (!cardId) {
            return;
        }

        const target = this.findAppointmentByCardId(cardId);

        if (!target) {
            this.showToast(
                'Unable to schedule',
                'Could not load this work order. Refresh and try again.',
                'warning'
            );
            return;
        }

        if (!this.hasScheduleAddress(target)) {
            this.showAddressRequiredHelp(cardId);
            return;
        }

        const startValue = this.quickScheduleSelections[cardId];

        if (!startValue) {
            this.showToast(
                'Pick a date and time',
                'Select a start date and time before scheduling.',
                'warning'
            );
            return;
        }

        const startDate = new Date(startValue);

        if (Number.isNaN(startDate.getTime())) {
            this.showToast(
                'Invalid date/time',
                'Enter a valid start date and time before scheduling.',
                'error'
            );
            return;
        }

        const durationHours =
            target.durationHours || this.defaultWorkOrderDurationHours || 1;
        const endDate = new Date(
            startDate.getTime() + durationHours * 60 * 60 * 1000
        );

        const selectedVisitAppointmentId =
            this.getSelectedVisitAppointmentId(target);

        if (selectedVisitAppointmentId) {
            this.rescheduleExistingAppointment(
                selectedVisitAppointmentId,
                startValue
            );
            return;
        }

        if (target.workOrderId) {
            this.createAppointmentFromWorkOrder(
                target.workOrderId,
                startDate.toISOString(),
                endDate.toISOString()
            );
        }
    }

    startScheduleOnCalendar(target) {
        if (!target) {
            return;
        }

        const cardId = target.cardId || target.appointmentId || target.workOrderId;

        if (!this.hasScheduleAddress(target)) {
            this.showAddressRequiredHelp(cardId);
            return;
        }

        this.updateActiveTabState('calendar');
        this.ensureCalendarReadyForScheduling(target);
    }

    ensureCalendarReadyForScheduling(target, attempt = 0) {
        const maxAttempts = 6;
        const dayEl = this.template.querySelector('.sfs-calendar-day');
        const dayBodyEl = this.template.querySelector('.sfs-calendar-day-body');

        if (!dayEl || !dayBodyEl) {
            if (attempt >= maxAttempts) {
                return;
            }

            this.safeSetTimeout(
                () => this.ensureCalendarReadyForScheduling(target, attempt + 1),
                120
            );

            return;
        }

        this.beginSchedulingGhost(target);
    }

    beginSchedulingGhost(target) {
        if (!target) {
            return;
        }

        this.isAwaitingScheduleConfirmation = false;
        this.pendingSchedulePlacement = null;

        const shouldRequireExplicitConfirmation =
            this.dragRequiresExplicitConfirmation;

        // When scheduling from the Unscheduled tab, place the ghost at a
        // predictable default time (12 PM local) and keep it anchored so the
        // user can pan the calendar without immediately entering drag mode.
        const isSelectedVisitScheduled = this.isSelectedVisitScheduled(target);
        const isUnscheduledWorkOrder = !isSelectedVisitScheduled;

        const dayIndex = this.resolveCalendarDayIndex(
            isSelectedVisitScheduled ? target.schedStart : null
        );

        const dayEl =
            this.template.querySelector(
                `.sfs-calendar-day[data-day-index="${dayIndex}"]`
            ) || this.template.querySelector('.sfs-calendar-day');

        const dayBodyEl = dayEl
            ? dayEl.querySelector('.sfs-calendar-day-body')
            : this.template.querySelector('.sfs-calendar-day-body');

        if (!dayEl || !dayBodyEl) {
            return;
        }

        if (isUnscheduledWorkOrder) {
            this.resetDragState();
            this.dragRequiresExplicitConfirmation = shouldRequireExplicitConfirmation;

            const placement = this.buildDefaultPlacementForWorkOrder(
                target,
                dayIndex
            );

            if (!placement) {
                return;
            }

            const dayRect = dayEl.getBoundingClientRect();
            const bodyRect = dayBodyEl.getBoundingClientRect();
            const totalHours = this.calendarEndHour - this.calendarStartHour || 24;
            const ghostHeight =
                (placement.durationHours / totalHours) *
                (bodyRect.height || dayBodyEl.clientHeight || 1);
            const ghostWidth = (dayRect.width || 1) * 0.88;

            const startLocal = this.convertUtcToUserLocal(placement.startIso);
            const endLocal = this.convertUtcToUserLocal(placement.endIso);
            const timeLabel = this.formatTimeRange(startLocal, endLocal);

            this.dragGhostVisible = true;
            this.dragGhostTitle = placement.title;
            this.dragGhostTime = timeLabel;
            this.dragGhostTypeClass = placement.typeClass;
            this.dragGhostWidth = ghostWidth;
            this.dragGhostHeight = ghostHeight;

            this.cachePendingSchedulePlacement(placement);
            return;
        }

        const bodyRect = dayBodyEl.getBoundingClientRect();
        const clientX = bodyRect.left + bodyRect.width / 2;
        const clientY = bodyRect.top + bodyRect.height * 0.25;
        const selectedVisitAppointmentId =
            this.getSelectedVisitAppointmentId(target);
        const pending = selectedVisitAppointmentId
            ? this.buildPendingEventFromList(
                  target,
                  selectedVisitAppointmentId,
                  dayIndex,
                  dayEl.clientWidth || bodyRect.width || 1,
                  bodyRect.height || dayBodyEl.clientHeight || 1,
                  bodyRect.top,
                  clientX,
                  clientY
              )
            : this.buildPendingWorkOrderFromList(
                  target,
                  dayIndex,
                  dayEl.clientWidth || bodyRect.width || 1,
                  bodyRect.height || dayBodyEl.clientHeight || 1,
                  bodyRect.top,
                  clientX,
                  clientY
              );

        if (!pending) {
            return;
        }

        this.resetDragState();
        this.dragRequiresExplicitConfirmation = shouldRequireExplicitConfirmation;
        this._pendingDrag = pending;
        this.beginDragFromPending();
    }

    buildPendingEventFromList(
        appt,
        appointmentId,
        dayIndex,
        dayWidth,
        dayBodyHeight,
        dayBodyTop,
        clientX,
        clientY
    ) {
        if (!appt || !appointmentId) {
            return null;
        }

        const localStart = appt.schedStart
            ? this.convertUtcToUserLocal(appt.schedStart)
            : new Date();

        return {
            type: 'event',
            id: appointmentId,
            dayIndex,
            localStart,
            clientX,
            clientY,
            dayBodyHeight,
            dayBodyTop,
            dayWidth,
            title: this.getServiceAppointmentDisplayTitle(appt)
        };
    }

    buildPendingWorkOrderFromList(
        workOrder,
        dayIndex,
        dayWidth,
        dayBodyHeight,
        dayBodyTop,
        clientX,
        clientY
    ) {
        if (!workOrder || !workOrder.workOrderId) {
            return null;
        }

        const title = workOrder.workOrderNumber
            ? `${workOrder.workOrderNumber} — ${workOrder.workOrderSubject ||
                  workOrder.subject ||
                  'New appointment'}`
            : workOrder.workOrderSubject || workOrder.subject || 'New appointment';

        return {
            type: 'wo',
            workOrderId: workOrder.workOrderId,
            visitAppointmentId: this.getSelectedVisitAppointmentId(workOrder),
            dayIndex,
            clientX,
            clientY,
            dayBodyHeight,
            dayBodyTop,
            dayWidth,
            title
        };
    }

    buildDefaultPlacementForWorkOrder(workOrder, dayIndex) {
        if (!workOrder || !workOrder.workOrderId) {
            return null;
        }

        const day = this.calendarDays && this.calendarDays[dayIndex];
        if (!day || !day.date) {
            return null;
        }

        const durationHours = this.defaultWorkOrderDurationHours || 1;
        const startLocal = new Date(day.date);

        const preferredHour = 12;
        const latestStartHour = Math.max(
            this.calendarStartHour,
            this.calendarEndHour - durationHours
        );
        const startHour = Math.max(
            this.calendarStartHour,
            Math.min(preferredHour, latestStartHour)
        );

        startLocal.setHours(startHour, 0, 0, 0);

        const endLocal = new Date(startLocal);
        endLocal.setHours(endLocal.getHours() + durationHours, 0, 0, 0);

        return {
            type: 'wo',
            workOrderId: workOrder.workOrderId,
            visitAppointmentId: this.getSelectedVisitAppointmentId(workOrder),
            dayIndex,
            startIso: this.toUserIsoString(startLocal),
            endIso: this.toUserIsoString(endLocal),
            durationHours,
            title: workOrder.workOrderNumber
                ? `${workOrder.workOrderNumber} — ${
                      workOrder.workOrderSubject || workOrder.subject || 'New appointment'
                  }`
                : workOrder.workOrderSubject ||
                  workOrder.subject ||
                  'New appointment',
            typeClass: 'sfs-event-default'
        };
    }

    resolveCalendarDayIndex(startDateLike) {
        if (this.calendarDays && this.calendarDays.length && startDateLike) {
            const targetDay = this.normalizeDayStart(
                this.convertUtcToUserLocal(startDateLike)
            );

            const index = this.calendarDays.findIndex(day => {
                const dayDate = this.normalizeDayStart(new Date(day.date));
                return dayDate && targetDay && dayDate.getTime() === targetDay.getTime();
            });

            if (index >= 0) {
                return index;
            }
        }

        if (this.todayDayIndex != null) {
            return this.todayDayIndex;
        }

        return 0;
    }

    normalizeDayStart(date) {
        if (!(date instanceof Date) || Number.isNaN(date.getTime())) {
            return null;
        }

        const clone = new Date(date);
        clone.setHours(0, 0, 0, 0);
        return clone;
    }

    updateAppointmentEndTime(appointmentId, newEndIso) {
        this.checkOnline();
        if (this.isOffline) {
            this.showToast(
                'Offline',
                'You must be online to change the appointment duration.',
                'warning'
            );
            return;
        }

        this.isLoading = true;

        updateAppointmentEnd({
            appointmentId,
            newEnd: newEndIso
        })
            .then(() => {
                this.showToast(
                    'Appointment updated',
                    'The appointment duration has been changed.',
                    'success'
                );
                return this.loadAppointments({ preserveScroll: true });
            })
            .then(() => {
                this.handleCalendarToday();
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.debugInfo = {
                    note: 'Error updating appointment end time',
                    errorMessage: message
                };
                this.showToast('Error updating appointment', message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleListInfoClick(event) {
        // When fired from child component, data arrives in event.detail.id
        if (event.detail?.id) {
            const cardId = event.detail.id;
            const appt = this.findAppointmentByCardId(cardId);
            this.safeClearTimeout(this._closeTimeout);
            this.isDetailClosing = false;
            this.selectedAbsence = null;
            this.selectedAppointment = appt ? { ...appt } : null;
            this.updateSelectedEventStyles();
            return;
        }
        this.handleEventClick(event);
    }

    navigateToServiceAppointment(serviceAppointmentId, fallbackWorkOrderId = null) {
        if (!serviceAppointmentId && fallbackWorkOrderId) {
            this.navigateToWorkOrderRecord(fallbackWorkOrderId);
            return;
        }

        try {
            const deepLink = `com.salesforce.fieldservice://v1/sObject/${serviceAppointmentId}`;
            this.navigateToUrl(deepLink);
            return;
        } catch (error) {
            console.error('Unable to open Service Appointment via Field Service deep link', error);
        }

        try {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: serviceAppointmentId,
                    objectApiName: 'ServiceAppointment',
                    actionName: 'view'
                }
            });
        } catch (error) {
            console.error('Unable to open Service Appointment record page', error);
            const deepLink = `/one/one.app#/sObject/${serviceAppointmentId}/view`;
            this.navigateToUrl(deepLink);
        }

        if (fallbackWorkOrderId) {
            this.navigateToWorkOrderRecord(fallbackWorkOrderId);
        }
    }

    navigateToWorkOrderRecord(workOrderId) {
        if (!workOrderId) {
            return;
        }

        try {
            const deepLink = `com.salesforce.fieldservice://v1/sObject/${workOrderId}`;
            this.navigateToUrl(deepLink);
            return;
        } catch (error) {
            console.error('Unable to open Work Order via Field Service deep link', error);
        }

        try {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: workOrderId,
                    objectApiName: 'WorkOrder',
                    actionName: 'view'
                }
            });
        } catch (error) {
            console.error('Unable to open Work Order record page', error);
            const deepLink = `/one/one.app#/sObject/${workOrderId}/view`;
            this.navigateToUrl(deepLink);
        }
    }

    navigateToOpportunityRecord(opportunityId) {
        if (!opportunityId) {
            return;
        }

        try {
            const deepLink = `com.salesforce.fieldservice://v1/sObject/${opportunityId}`;
            this.navigateToUrl(deepLink);
            return;
        } catch (error) {
            console.error('Unable to open Opportunity via Field Service deep link', error);
        }

        try {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: opportunityId,
                    objectApiName: 'Opportunity',
                    actionName: 'view'
                }
            });
        } catch (error) {
            console.error('Unable to open Opportunity record page', error);
            const deepLink = `/one/one.app#/sObject/${opportunityId}/view`;
            this.navigateToUrl(deepLink);
        }
    }

    // ======= EVENT CLICK =======

    handleEventClick(event) {
        if (this.dragHasMoved) {
            this.dragHasMoved = false;
            return;
        }

        const id = event.currentTarget.dataset.id;
        const kind = event.currentTarget.dataset.kind || 'appointment';
        if (!id) {
            return;
        }

        if (kind === 'absence') {
            const absence = this.findAbsenceById(id);
            this.safeClearTimeout(this._closeTimeout);
            this.isDetailClosing = false;
            this.selectedAppointment = null;
            this.selectedAbsence = absence
                ? { ...absence, newStart: absence.newStart || absence.start, newEnd: absence.newEnd || absence.endTime }
                : null;
            this.updateSelectedEventStyles();
            return;
        }

        const appt = this.findAppointmentByCardId(id);

        this.safeClearTimeout(this._closeTimeout);
        this.isDetailClosing = false;
        this.selectedAbsence = null;
        this.selectedAppointment = appt ? { ...appt } : null;
        this.updateSelectedEventStyles();
    }

    // ======= DETAIL OVERLAY =======

    handleCloseDetails(event) {
        if (event) {
            event.stopPropagation();
        }

        if (!this.selectedAppointment || this.isDetailClosing) {
            return;
        }

        this.isDetailClosing = true;

        this.safeClearTimeout(this._closeTimeout);
        this._closeTimeout = this.safeSetTimeout(() => {
            this.selectedAppointment = null;
            this.isDetailClosing = false;
            this.updateSelectedEventStyles();
        }, 200);
    }

    handleDetailCardClick(event) {
        event.stopPropagation();
    }

    // ======= ADDRESS EDITING =======

    isFedExAddress(entry) {
        const name = this.normalizeAddressValue(entry?.name || '').toLowerCase();
        return name.includes('fedex');
    }

    getAddressOptionLabels(entry) {
        const label = this.composeFullAddress({
            street: entry.street,
            city: entry.city,
            state: entry.stateCode || entry.state,
            postalCode: entry.postalCode,
            country: entry.country || entry.countryCode
        });
        const baseLabel = entry.name
            ? `${entry.name} — ${label || 'Saved address'}`
            : label || 'Saved address';
        const isFedEx = this.isFedExAddress(entry);
        const displayLabel =
            isFedEx && !baseLabel.toLowerCase().includes('fedex')
                ? `FedEx — ${baseLabel}`
                : baseLabel;

        return {
            baseLabel,
            displayLabel,
            isFedEx
        };
    }

    loadUserShippingAddresses() {
        if (this._shippingAddressLoadPromise) {
            return this._shippingAddressLoadPromise;
        }

        this._shippingAddressLoadPromise = getUserAddressBook()
            .then(results => {
                const safeResults = Array.isArray(results) ? results : [];
                const addressBook = safeResults.map(item => ({
                    addressId: item.addressId,
                    locationId: item.locationId,
                    name: this.normalizeAddressValue(item.name),
                    street: this.normalizeAddressValue(item.street),
                    city: this.normalizeAddressValue(item.city),
                    state: this.normalizeAddressValue(item.state),
                    stateCode: this.normalizeAddressValue(item.stateCode),
                    country: this.normalizeAddressValue(item.country),
                    countryCode: this.normalizeAddressValue(item.countryCode),
                    postalCode: this.normalizeAddressValue(item.postalCode)
                }));

                const sortedBook = addressBook
                    .map(entry => {
                        const labels = this.getAddressOptionLabels(entry);
                        return {
                            ...entry,
                            _addressLabel: labels.baseLabel,
                            _addressDisplayLabel: labels.displayLabel,
                            _isFedExAddress: labels.isFedEx
                        };
                    })
                    .sort((left, right) => {
                        if (left._isFedExAddress !== right._isFedExAddress) {
                            return left._isFedExAddress ? -1 : 1;
                        }

                        return left._addressLabel.localeCompare(
                            right._addressLabel
                        );
                    });

                this.shippingAddressBook = sortedBook;
                this.shippingAddressOptions = sortedBook.map(entry => ({
                    label: entry._addressDisplayLabel,
                    value: entry.addressId
                }));

                if (this.shippingAddressOptions.length === 0) {
                    this.shippingAddressMode = 'manual';
                }
            })
            .catch(error => {
                console.error('Unable to load saved addresses', error);
                this.shippingAddressBook = [];
                this.shippingAddressOptions = [];
                this.shippingAddressMode = 'manual';
            });

        return this._shippingAddressLoadPromise;
    }

    _extractModalEventContext(event) {
        const detail = event?.detail || {};
        const dataset = event?.currentTarget?.dataset || {};
        const cardId = detail.id || detail.cardId || dataset.id || dataset.cardId || null;
        const workOrderId = detail.woid || detail.workorderid || dataset.woid || dataset.workorderid || null;
        const appointmentId = detail.appointmentId || detail.appointmentid ||
            dataset.appointmentId || dataset.appointmentid || null;
        const record = this.findAppointmentByCardId(cardId) ||
            (workOrderId ? (this.unscheduledWorkOrders || []).find(wo => wo.workOrderId === workOrderId) : null);
        return { cardId, workOrderId, appointmentId, record };
    }

    openShippingAddressModal(event) {
        const { cardId, workOrderId, appointmentId, record } = this._extractModalEventContext(event);

        const rawState = this.normalizeAddressValue(record?.shippingState);
        const initialState =
            rawState.length > 2 ? '' : this.normalizeStateInput(rawState);

        this.shippingAddressForm = {
            attn: this.normalizeAddressValue(record?.shippingAttn),
            shippingSiteName: this.normalizeAddressValue(
                record?.shippingSiteName || record?.serviceSiteName
            ),
            street: this.normalizeAddressValue(record?.shippingStreet),
            city: this.normalizeAddressValue(record?.shippingCity),
            state: initialState,
            country:
                this.normalizeAddressValue(record?.shippingCountry) ||
                'United States',
            postalCode: this.normalizeAddressValue(record?.shippingPostalCode)
        };

        this.shippingAddressModalWorkOrderId =
            workOrderId || record?.workOrderId || null;
        this.shippingAddressModalAppointmentId =
            appointmentId || record?.appointmentId || null;
        this.shippingAddressModalCardId = cardId;
        this.isShippingAddressModalOpen = true;
        this.shippingAddressSaving = false;
        this.shippingAddressSelection = '';

        this.loadUserShippingAddresses().finally(() => {
            if (this.shippingAddressOptions.length > 0) {
                this.shippingAddressMode = 'saved';
            } else {
                this.shippingAddressMode = 'manual';
            }
        });

        this.prefillShippingAddressState(rawState, cardId);
    }

    closeShippingAddressModal() {
        clearTimeout(this._shippingAddressInputDebounceTimer);
        this._shippingAddressFormPending = null;
        this.isShippingAddressModalOpen = false;
        this.shippingAddressSaving = false;
        this.shippingAddressModalWorkOrderId = null;
        this.shippingAddressModalAppointmentId = null;
        this.shippingAddressModalCardId = null;
        this.shippingAddressSelection = '';
        this.repairDeclineShippingEditPending = false;
        this.shippingAddressForm = {
            attn: '',
            shippingSiteName: '',
            street: '',
            city: '',
            state: '',
            country: 'United States',
            postalCode: ''
        };
    }

    handleShippingAddressModeChange(event) {
        this.shippingAddressMode = event.detail.value;
    }

    handleShippingAddressSelection(event) {
        const value =
            (event.detail && event.detail.value) || event.target.value || '';
        this.shippingAddressSelection = value;

        const match = (this.shippingAddressBook || []).find(
            item => item.addressId === value
        );

        if (!match) {
            return;
        }

        const stateValue = match.stateCode || match.state;
        const rawState = this.normalizeAddressValue(stateValue);
        const initialState =
            rawState.length > 2 ? '' : this.normalizeStateInput(rawState);

        this.shippingAddressForm = {
            ...this.shippingAddressForm,
            street: match.street,
            city: match.city,
            state: initialState,
            country: match.country || match.countryCode || 'United States',
            postalCode: match.postalCode
        };

        this.prefillShippingAddressState(rawState, this.shippingAddressModalCardId);
    }

    handleShippingAddressInputChange(event) {
        const field = event.target.name;
        const value =
            (event.detail && event.detail.value) || event.target.value || '';

        const nextValue =
            field === 'state' ? this.normalizeStateInput(value) : value;

        const currentValue = this._shippingAddressFormPending?.[field] ?? this.shippingAddressForm?.[field];
        if (currentValue === nextValue) {
            return;
        }

        this._shippingAddressFormPending = { ...(this._shippingAddressFormPending || {}), [field]: nextValue };
        clearTimeout(this._shippingAddressInputDebounceTimer);
        this._shippingAddressInputDebounceTimer = setTimeout(() => {
            this.shippingAddressForm = { ...this.shippingAddressForm, ...this._shippingAddressFormPending };
            this._shippingAddressFormPending = null;
        }, 150);
    }

    _flushShippingAddressInputChanges() {
        if (!this._shippingAddressFormPending) return;
        clearTimeout(this._shippingAddressInputDebounceTimer);
        this.shippingAddressForm = { ...this.shippingAddressForm, ...this._shippingAddressFormPending };
        this._shippingAddressFormPending = null;
    }

    prefillShippingAddressState(stateValue, cardId) {
        const rawState = this.normalizeAddressValue(stateValue);
        if (!rawState || rawState.length <= 2) {
            return;
        }

        getStateAbbreviation({ stateName: rawState })
            .then(abbreviation => {
                const normalized = this.normalizeStateInput(abbreviation);
                if (!normalized) {
                    return;
                }

                if (
                    !this.isShippingAddressModalOpen ||
                    this.shippingAddressModalCardId !== cardId
                ) {
                    return;
                }

                this.shippingAddressForm = {
                    ...this.shippingAddressForm,
                    state: normalized
                };
            })
            .catch(error => {
                console.error('Unable to translate shipping state name', error);
            });
    }

    openAddressModal(event) {
        const { cardId, workOrderId, appointmentId, record } = this._extractModalEventContext(event);

        const rawState = this.normalizeAddressValue(record?.state);
        const initialState =
            rawState.length > 2 ? '' : this.normalizeStateInput(rawState);

        this.addressForm = {
            street: this.normalizeAddressValue(record?.street),
            city: this.normalizeAddressValue(record?.city),
            state: initialState,
            country:
                this.normalizeAddressValue(record?.country) || 'United States',
            postalCode: this.normalizeAddressValue(record?.postalCode)
        };

        this.addressModalWorkOrderId =
            workOrderId || record?.workOrderId || null;
        this.addressModalAppointmentId =
            appointmentId || record?.appointmentId || null;
        this.addressModalCardId = cardId;
        this.isAddressModalOpen = true;
        this.addressSaving = false;
        this.addressSelection = '';

        this.prefillAddressState(rawState, cardId);

        this.loadUserShippingAddresses().finally(() => {
            if (this.shippingAddressOptions.length > 0) {
                this.addressMode = 'saved';
            } else {
                this.addressMode = 'manual';
            }
        });
    }

    closeAddressModal() {
        clearTimeout(this._addressInputDebounceTimer);
        this._addressFormPending = null;
        this.isAddressModalOpen = false;
        this.addressSaving = false;
        this.addressModalWorkOrderId = null;
        this.addressModalAppointmentId = null;
        this.addressModalCardId = null;
        this.addressMode = 'saved';
        this.addressSelection = '';
        this.addressForm = {
            street: '',
            city: '',
            state: '',
            country: 'United States',
            postalCode: ''
        };
    }

    handleAddressInputChange(event) {
        const field = event.target.name;
        const value =
            (event.detail && event.detail.value) || event.target.value || '';

        const nextValue =
            field === 'state' ? this.normalizeStateInput(value) : value;

        const currentValue = this._addressFormPending?.[field] ?? this.addressForm?.[field];
        if (currentValue === nextValue) {
            return;
        }

        this._addressFormPending = { ...(this._addressFormPending || {}), [field]: nextValue };
        clearTimeout(this._addressInputDebounceTimer);
        this._addressInputDebounceTimer = setTimeout(() => {
            this.addressForm = { ...this.addressForm, ...this._addressFormPending };
            this._addressFormPending = null;
        }, 150);
    }

    _flushAddressInputChanges() {
        if (!this._addressFormPending) return;
        clearTimeout(this._addressInputDebounceTimer);
        this.addressForm = { ...this.addressForm, ...this._addressFormPending };
        this._addressFormPending = null;
    }

    handleAddressModeChange(event) {
        this.addressMode = event.detail.value;
    }

    handleAddressSelection(event) {
        const value =
            (event.detail && event.detail.value) || event.target.value || '';
        this.addressSelection = value;

        const match = (this.shippingAddressBook || []).find(
            item => item.addressId === value
        );

        if (!match) {
            return;
        }

        const stateValue = match.stateCode || match.state;
        const rawState = this.normalizeAddressValue(stateValue);
        const initialState =
            rawState.length > 2 ? '' : this.normalizeStateInput(rawState);

        this.addressForm = {
            ...this.addressForm,
            street: match.street,
            city: match.city,
            state: initialState,
            country: match.country || match.countryCode || 'United States',
            postalCode: match.postalCode
        };

        this.prefillAddressState(rawState, this.addressModalCardId);
    }

    prefillAddressState(stateValue, cardId) {
        const rawState = this.normalizeAddressValue(stateValue);
        if (!rawState || rawState.length <= 2) {
            return;
        }

        getStateAbbreviation({ stateName: rawState })
            .then(abbreviation => {
                const normalized = this.normalizeStateInput(abbreviation);
                if (!normalized) {
                    return;
                }

                if (
                    !this.isAddressModalOpen ||
                    this.addressModalCardId !== cardId
                ) {
                    return;
                }

                this.addressForm = {
                    ...this.addressForm,
                    state: normalized
                };
            })
            .catch(error => {
                console.error('Unable to translate state name', error);
            });
    }

    submitAddressUpdate() {
        this._flushAddressInputChanges();
        const workOrderId = this.addressModalWorkOrderId;
        const serviceAppointmentId = this.addressModalAppointmentId;
        let payload = null;

        if (!workOrderId) {
            this.showToast(
                'Missing work order',
                'Select a work order before saving the address.',
                'error'
            );
            return;
        }

        if (this.addressMode === 'saved') {
            const selected = (this.shippingAddressBook || []).find(
                item => item.addressId === this.addressSelection
            );

            if (!selected) {
                this.showToast(
                    'Select an address',
                    'Choose a saved address before saving.',
                    'warning'
                );
                return;
            }

            const stateValue = selected.stateCode || selected.state;
            const normalizedState = this.normalizeStateInput(stateValue);

            if (!this.isValidStateAbbreviation(normalizedState)) {
                this.showToast(
                    'State abbreviation',
                    'Enter the 2-letter state abbreviation (A-Z).',
                    'warning'
                );
                return;
            }

            payload = {
                street: selected.street,
                city: selected.city,
                state: normalizedState,
                postalCode: selected.postalCode,
                country: selected.country || selected.countryCode
            };
        } else {
            const stateAbbreviation = this.normalizeStateInput(
                this.addressForm.state
            );

            if (!this.hasCompleteAddress(this.addressForm)) {
                this.showToast(
                    'Add address',
                    'Street, City, State, Postal Code, and Country are required.',
                    'warning'
                );
                return;
            }

            if (!this.isValidStateAbbreviation(stateAbbreviation)) {
                this.showToast(
                    'State abbreviation',
                    'Enter the 2-letter state abbreviation (A-Z).',
                    'warning'
                );
                return;
            }

            payload = {
                street: this.addressForm.street,
                city: this.addressForm.city,
                state: stateAbbreviation,
                postalCode: this.addressForm.postalCode,
                country: this.addressForm.country
            };
        }

        if (!payload) {
            return;
        }

        this.addressSaving = true;

        updateWorkOrderAddress({
            workOrderId,
            serviceAppointmentId,
            street: payload.street,
            city: payload.city,
            state: payload.state,
            postalCode: payload.postalCode,
            country: payload.country
        })
            .then(result => {
                this.applyAddressUpdate(result);
                this.showToast(
                    'Address saved',
                    'The work order address was updated.',
                    'success'
                );
                this.closeAddressModal();
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.showToast('Error saving address', message, 'error');
            })
            .finally(() => {
                this.addressSaving = false;
            });
    }

    applyAddressUpdate(result) {
        if (!result) {
            return;
        }

        const address = {
            street: this.normalizeAddressValue(result.street),
            city: this.normalizeAddressValue(result.city),
            state: this.normalizeAddressValue(result.state),
            country:
                this.normalizeAddressValue(result.country) || 'United States',
            postalCode: this.normalizeAddressValue(result.postalCode)
        };

        address.fullAddress = this.composeFullAddress(address);

        const workOrderId = result.workOrderId;
        const appointmentId = result.serviceAppointmentId;

        this.appointments = (this.appointments || []).map(appt => {
            if (
                (workOrderId && appt.workOrderId === workOrderId) ||
                (appointmentId && appt.appointmentId === appointmentId)
            ) {
                const fullAddress = address.fullAddress;
                return {
                    ...appt,
                    ...address,
                    fullAddress,
                    hasFullAddress: this.hasStreetValue(address)
                };
            }
            return appt;
        });

        this.unscheduledWorkOrders = (this.unscheduledWorkOrders || []).map(
            wo => {
                if (wo.workOrderId === workOrderId) {
                    const fullAddress = address.fullAddress;
                    return {
                        ...wo,
                        ...address,
                        fullAddress,
                        hasFullAddress: this.hasStreetValue(address)
                    };
                }
                return wo;
            }
        );

        if (
            this.selectedAppointment &&
            ((workOrderId &&
                this.selectedAppointment.workOrderId === workOrderId) ||
                (appointmentId &&
                    this.selectedAppointment.appointmentId === appointmentId))
        ) {
            const fullAddress = address.fullAddress;
            this.selectedAppointment = {
                ...this.selectedAppointment,
                ...address,
                fullAddress,
                hasFullAddress: this.hasStreetValue(address)
            };
        }

        this.addressHelpCardId = null;
        this.safeClearTimeout(this._addressHelpTimeout);
    }

    submitShippingAddressUpdate() {
        this._flushShippingAddressInputChanges();
        const workOrderId = this.shippingAddressModalWorkOrderId;
        const serviceAppointmentId = this.shippingAddressModalAppointmentId;
        let payload = null;

        if (!workOrderId) {
            this.showToast(
                'Missing work order',
                'Select a work order before saving the shipping address.',
                'error'
            );
            return;
        }

        if (this.shippingAddressMode === 'saved') {
            const selected = (this.shippingAddressBook || []).find(
                item => item.addressId === this.shippingAddressSelection
            );

            if (!selected) {
                this.showToast(
                    'Select an address',
                    'Choose a saved address before saving.',
                    'warning'
                );
                return;
            }

            const stateValue = selected.stateCode || selected.state;
            const normalizedState = this.normalizeStateInput(stateValue);

            if (!this.isValidStateAbbreviation(normalizedState)) {
                this.showToast(
                    'State abbreviation',
                    'Enter the 2-letter state abbreviation (A-Z).',
                    'warning'
                );
                return;
            }

            payload = {
                attn: this.shippingAddressForm.attn,
                shippingSiteName: this.shippingAddressForm.shippingSiteName,
                locationId: selected.locationId || null,
                addressId: selected.addressId || null,
                street: selected.street,
                city: selected.city,
                state: normalizedState,
                postalCode: selected.postalCode,
                country: selected.country || selected.countryCode,
                countryCode: selected.countryCode || selected.country
            };
        } else {
            const stateAbbreviation = this.normalizeStateInput(
                this.shippingAddressForm.state
            );

            if (!this.hasCompleteAddress(this.shippingAddressForm)) {
                this.showToast(
                    'Add shipping address',
                    'Street, City, State, Postal Code, and Country are required.',
                    'warning'
                );
                return;
            }

            if (!this.isValidStateAbbreviation(stateAbbreviation)) {
                this.showToast(
                    'State abbreviation',
                    'Enter the 2-letter state abbreviation (A-Z).',
                    'warning'
                );
                return;
            }

            payload = {
                attn: this.shippingAddressForm.attn,
                shippingSiteName: this.shippingAddressForm.shippingSiteName,
                locationId: null,
                addressId: null,
                street: this.shippingAddressForm.street,
                city: this.shippingAddressForm.city,
                state: stateAbbreviation,
                postalCode: this.shippingAddressForm.postalCode,
                country: this.shippingAddressForm.country,
                countryCode: ''
            };
        }

        if (!payload) {
            return;
        }

        this.shippingAddressSaving = true;

        updateWorkOrderShippingAddress({
            workOrderId,
            serviceAppointmentId,
            locationId: payload.locationId,
            addressId: payload.addressId,
            attn: payload.attn,
            shippingSiteName: payload.shippingSiteName,
            street: payload.street,
            city: payload.city,
            state: payload.state,
            postalCode: payload.postalCode,
            country: payload.country,
            countryCode: payload.countryCode
        })
            .then(result => {
                this.applyShippingAddressUpdate(result);
                this.showToast(
                    'Shipping address saved',
                    'The shipping address was updated.',
                    'success'
                );
                const wasDeclinePending = this.repairDeclineShippingEditPending;
                this.closeShippingAddressModal();
                if (wasDeclinePending) {
                    const freshRecord = this.findRecordByWorkOrderId(this.repairDeclineConfirmWorkOrderId);
                    if (freshRecord) {
                        this.repairDeclineConfirmRecord = freshRecord;
                    }
                    this.isRepairDeclineConfirmModalOpen = true;
                }
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.showToast('Error saving shipping address', message, 'error');
            })
            .finally(() => {
                this.shippingAddressSaving = false;
            });
    }

    applyShippingAddressUpdate(result) {
        if (!result) {
            return;
        }

        const shipping = {
            shippingAttn: this.normalizeAddressValue(result.shippingAttn),
            shippingSiteName: this.normalizeAddressValue(result.shippingSiteName),
            shippingStreet: this.normalizeAddressValue(result.shippingStreet),
            shippingCity: this.normalizeAddressValue(result.shippingCity),
            shippingState: this.normalizeAddressValue(result.shippingState),
            shippingCountry: this.normalizeAddressValue(result.shippingCountry),
            shippingPostalCode: this.normalizeAddressValue(
                result.shippingPostalCode
            )
        };

        shipping.shippingFullAddress = this.composeFullAddress({
            street: shipping.shippingStreet,
            city: shipping.shippingCity,
            state: shipping.shippingState,
            postalCode: shipping.shippingPostalCode,
            country: shipping.shippingCountry
        });

        const hasShippingAddress =
            Boolean(shipping.shippingAttn) ||
            Boolean(shipping.shippingFullAddress);
        const hasCompleteShippingAddress = this.hasCompleteAddress({
            street: shipping.shippingStreet,
            city: shipping.shippingCity,
            state: shipping.shippingState,
            postalCode: shipping.shippingPostalCode,
            country: shipping.shippingCountry
        });

        const workOrderId = result.workOrderId;
        const appointmentId = result.serviceAppointmentId;

        this.appointments = (this.appointments || []).map(appt => {
            if (
                (workOrderId && appt.workOrderId === workOrderId) ||
                (appointmentId && appt.appointmentId === appointmentId)
            ) {
                return {
                    ...appt,
                    ...shipping,
                    hasShippingAddress,
                    hasShippingAttn: Boolean(shipping.shippingAttn),
                    hasCompleteShippingAddress
                };
            }
            return appt;
        });

        this.unscheduledWorkOrders = (this.unscheduledWorkOrders || []).map(
            wo => {
                if (wo.workOrderId === workOrderId) {
                    return {
                        ...wo,
                        ...shipping,
                        hasShippingAddress,
                        hasShippingAttn: Boolean(shipping.shippingAttn),
                        hasCompleteShippingAddress
                    };
                }
                return wo;
            }
        );

        if (
            this.selectedAppointment &&
            ((workOrderId &&
                this.selectedAppointment.workOrderId === workOrderId) ||
                (appointmentId &&
                    this.selectedAppointment.appointmentId === appointmentId))
        ) {
            this.selectedAppointment = {
                ...this.selectedAppointment,
                ...shipping,
                hasShippingAddress,
                hasShippingAttn: Boolean(shipping.shippingAttn),
                hasCompleteShippingAddress
            };
        }
    }

    // ======= ACCOUNT EDITING =======

    openAccountModal(event) {
        const { cardId, workOrderId, appointmentId, record } = this._extractModalEventContext(event);

        this.accountForm = {
            name: this.normalizeAccountValue(record?.accountNameFreeText)
        };

        this.accountModalWorkOrderId =
            workOrderId || record?.workOrderId || null;
        this.accountModalAppointmentId =
            appointmentId || record?.appointmentId || null;
        this.accountModalCardId = cardId;
        this.isAccountModalOpen = true;
        this.accountSaving = false;
    }

    closeAccountModal() {
        this.isAccountModalOpen = false;
        this.accountSaving = false;
        this.accountModalWorkOrderId = null;
        this.accountModalAppointmentId = null;
        this.accountModalCardId = null;
        this.accountForm = {
            name: ''
        };
    }

    handleAccountInputChange(event) {
        const value =
            (event.detail && event.detail.value) || event.target.value || '';

        this.accountForm = {
            ...this.accountForm,
            name: value
        };
    }

    submitAccountUpdate() {
        const workOrderId = this.accountModalWorkOrderId;
        const accountName = this.normalizeAccountValue(this.accountForm.name);

        if (!workOrderId) {
            this.showToast(
                'Missing work order',
                'Select a work order before saving the account.',
                'error'
            );
            return;
        }

        if (!accountName) {
            this.showToast(
                'Add account',
                'Enter the account name before saving.',
                'warning'
            );
            return;
        }

        this.accountSaving = true;

        updateWorkOrderAccountName({
            workOrderId,
            accountName
        })
            .then(result => {
                this.applyAccountUpdate(result);
                this.showToast(
                    'Account saved',
                    'The work order account was updated.',
                    'success'
                );
                this.closeAccountModal();
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.showToast('Error saving account', message, 'error');
            })
            .finally(() => {
                this.accountSaving = false;
            });
    }

    applyAccountUpdate(result) {
        if (!result) {
            return;
        }

        const workOrderId = result.workOrderId;
        const accountNameFreeText = this.normalizeAccountValue(
            result.accountNameFreeText
        );

        this.updateRecordsByWorkOrderId(workOrderId, record =>
            this.applyAccountPresentation({ ...record, accountNameFreeText })
        );
    }

    // ======= REPORTER CONTACT EDITING =======

    openReporterContactModal(event) {
        const { cardId, workOrderId, appointmentId, record } = this._extractModalEventContext(event);

        this.reporterContactForm = {
            info: this.normalizeReporterContactValue(
                record?.reporterContactInfo
            )
        };
        this.reporterContactModalWorkOrderId =
            workOrderId || record?.workOrderId || null;
        this.reporterContactModalAppointmentId =
            appointmentId || record?.appointmentId || null;
        this.reporterContactModalCardId = cardId;
        this.isReporterContactModalOpen = true;
        this.reporterContactSaving = false;
    }

    closeReporterContactModal() {
        this.isReporterContactModalOpen = false;
        this.reporterContactSaving = false;
        this.reporterContactModalWorkOrderId = null;
        this.reporterContactModalAppointmentId = null;
        this.reporterContactModalCardId = null;
        this.reporterContactForm = {
            info: ''
        };
    }

    handleReporterContactInputChange(event) {
        const value =
            (event.detail && event.detail.value) || event.target.value || '';

        this.reporterContactForm = {
            ...this.reporterContactForm,
            info: value
        };
    }

    submitReporterContactUpdate() {
        const workOrderId = this.reporterContactModalWorkOrderId;
        const reporterContactInfo = this.normalizeReporterContactValue(
            this.reporterContactForm.info
        );

        if (!workOrderId) {
            this.showToast(
                'Missing work order',
                'Select a work order before saving the contact info.',
                'error'
            );
            return;
        }

        if (!reporterContactInfo) {
            this.showToast(
                'Add contact info',
                'Enter contact info before saving.',
                'warning'
            );
            return;
        }

        this.reporterContactSaving = true;

        updateWorkOrderReporterContactInfo({
            workOrderId,
            reporterContactInfo
        })
            .then(result => {
                this.applyReporterContactUpdate(result);
                this.showToast(
                    'Contact info saved',
                    'The contact info was updated.',
                    'success'
                );
                this.closeReporterContactModal();
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.showToast(
                    'Error saving contact info',
                    message,
                    'error'
                );
            })
            .finally(() => {
                this.reporterContactSaving = false;
            });
    }

    applyReporterContactUpdate(result) {
        if (!result) {
            return;
        }

        const workOrderId = result.workOrderId;
        const reporterContactInfo = this.normalizeReporterContactValue(
            result.reporterContactInfo
        );
        const updatedContactName = result.contactName || null;
        const updatedContactPhone = result.contactPhone || null;
        const updatedContactEmail = result.contactEmail || null;
        const reporter = this.parseReporterInfo(reporterContactInfo);

        const applyReporterUpdate = record => {
            const next = {
                ...record,
                reporterContactInfo,
                reporterName: reporter.name,
                reporterPhone: reporter.phone,
                reporterPhoneDisplay: reporter.phoneDisplay,
                reporterPhoneHref: reporter.phoneHref,
                reporterEmail: reporter.email,
                reporterEmailHref: reporter.emailHref
            };

            next.contactName =
                updatedContactName ||
                next.contactName ||
                reporter.name ||
                reporterContactInfo;
            next.contactPhone =
                updatedContactPhone || next.contactPhone || reporter.phoneDisplay;
            next.contactEmail =
                updatedContactEmail || next.contactEmail || reporter.email;

            if (next.contactPhone) {
                const digits = next.contactPhone.replace(/\D/g, '');
                next.contactPhoneHref = digits ? `tel:${digits}` : null;
            } else {
                next.contactPhoneHref = reporter.phoneHref || null;
            }

            next.contactEmailHref = next.contactEmail
                ? `mailto:${encodeURIComponent(next.contactEmail)}`
                : reporter.emailHref || null;

            next.hasDetailSection = Boolean(
                next.contactPhoneHref ||
                    next.contactEmailHref ||
                    next.reporterContactInfo
            );
            next.canAddReporterContact = this.canAddReporterContact(next);
            return next;
        };

        this.updateRecordsByWorkOrderId(workOrderId, applyReporterUpdate);
    }

    // ======= DETAIL SCHEDULING =======
    handleOpenQuickScheduleFromDetail() {
        const cardId = this.selectedQuickScheduleCardId;

        if (!cardId) {
            return;
        }

        if (!this.hasScheduleAddress(this.selectedAppointment)) {
            this.showAddressRequiredHelp(cardId);
            return;
        }

        this.ensureQuickScheduleSelection(cardId, this.selectedAppointment);

        this.quickScheduleExpanded = {
            ...this.quickScheduleExpanded,
            [cardId]: true
        };
    }


    // ======= ABSENCE EDITING =======

    handleAbsenceDateChange(event) {
        if (!this.selectedAbsence) {
            return;
        }

        const field = event.target.dataset.field;
        if (!field) {
            return;
        }

        const value = event.detail ? event.detail.value : event.target.value;
        this.selectedAbsence = { ...this.selectedAbsence, [field]: value };
    }

    handleSaveAbsence() {
        if (!this.selectedAbsence) {
            return;
        }

        const { absenceId, newStart, newEnd } = this.selectedAbsence;
        this.isLoading = true;

        updateResourceAbsence({
            absenceId,
            startDateTimeIso: newStart,
            endDateTimeIso: newEnd
        })
            .then(() => {
                this.showToast(
                    'Absence updated',
                    'Absence time updated.',
                    'success'
                );
                this.selectedAbsence = null;
                return this.loadAppointments({ preserveScroll: true });
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.showToast('Error updating absence', message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleDeleteAbsenceClick(event) {
        if (event) {
            event.stopPropagation();
        }

        const id = event && event.currentTarget ? event.currentTarget.dataset.id : null;
        const absenceId = id || (this.selectedAbsence ? this.selectedAbsence.absenceId : null);

        if (!absenceId) {
            return;
        }

        this.isLoading = true;

        deleteResourceAbsence({ absenceId })
            .then(() => {
                this.showToast(
                    'Absence deleted',
                    'The absence has been removed from the calendar.',
                    'success'
                );
                if (
                    this.selectedAbsence &&
                    this.selectedAbsence.absenceId === absenceId
                ) {
                    this.selectedAbsence = null;
                }
                return this.loadAppointments({ preserveScroll: true });
            })
            .then(() => {
                this.handleCalendarToday();
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.showToast('Error deleting absence', message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleCloseAbsenceDetails(event) {
        if (event) {
            event.stopPropagation();
        }

        if (!this.selectedAbsence || this.isAbsenceDetailClosing) {
            return;
        }

        this.isAbsenceDetailClosing = true;

        this.safeClearTimeout(this._absenceCloseTimeout);
        this._absenceCloseTimeout = this.safeSetTimeout(() => {
            this.selectedAbsence = null;
            this.isAbsenceDetailClosing = false;
            this.updateSelectedEventStyles();
        }, 200);
    }

    navigateToRecord(recordId, objectApiName) {
        if (!recordId) {
            return;
        }

        if (this.isDesktopFormFactor) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId,
                    objectApiName,
                    actionName: 'view'
                }
            });
        } else {
            const deepLink = `com.salesforce.fieldservice://v1/sObject/${recordId}`;

            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: deepLink
                }
            });
        }
    }

    handleOpenWorkOrder() {
        if (
            !this.selectedAppointment ||
            (!this.selectedAppointment.appointmentId &&
                !this.selectedAppointment.workOrderId)
        ) {
            return;
        }

        const { appointmentId, workOrderId } = this.selectedAppointment;

        if (workOrderId) {
            this.navigateToWorkOrderRecord(workOrderId);
            return;
        }

        if (appointmentId) {
            this.navigateToServiceAppointment(appointmentId, null);
        }
    }

    handleOpenAccount() {
        if (
            !this.selectedAppointment ||
            !this.selectedAppointment.accountId
        ) {
            return;
        }

        this.navigateToRecord(this.selectedAppointment.accountId, 'Account');
    }

    handleOpenContact() {
        if (
            !this.selectedAppointment ||
            !this.selectedAppointment.contactId
        ) {
            return;
        }

        this.navigateToRecord(this.selectedAppointment.contactId, 'Contact');
    }

    // ======= CALENDAR TAB HANDLERS =======

    handleManagerUserChange(event) {
        this.selectedManagerUserId = event.detail.value || null;
        const selected = (this.managerTeam || []).find(
            m => m.userId === this.selectedManagerUserId
        );
        this.selectedManagerUserName = selected ? selected.name : '';
    }

    handleManagerApply() {
        const targetId = this.selectedManagerUserId || this.currentUserId;
        this.activeUserId = targetId;
        this.viewingUserName = this.resolveViewingName();
        this.loadAppointments();
    }

    handleManagerReset() {
        this.selectedManagerUserId = null;
        this.selectedManagerUserName = '';
        this.activeUserId = this.currentUserId;
        this.viewingUserName = this.resolveViewingName();
        this.loadAppointments();
    }


    getDataScopeForTab(tabValue) {
        switch (tabValue) {
            case 'preventativeMaintenance':
                return 'preventativeMaintenance';
            case 'recent':
                return 'recent';
            case 'history':
                return 'history';
            case 'calendar':
                return 'calendar';
            case 'list':
            default:
                return 'salesAndService';
        }
    }

    handleRmaTabClick() {
        this.updateActiveTabState('rma');
        if (!this.rmaLoaded && !this.isRmaLoading) {
            this.loadRmas();
        }
    }

    loadRmas() {
        this.isRmaLoading = true;
        getRmasForCurrentEngineer()
            .then(result => {
                this.rmaItems = result || [];
                this.rmaLoaded = true;
            })
            .catch(error => {
                this.showToast('Unable to load RMAs', this.reduceError(error), 'error');
            })
            .finally(() => {
                this.isRmaLoading = false;
            });
    }

    handleRmaTrackingInput(event) {
        const rmaId = event.currentTarget.dataset.rmaId;
        const draft = { ...this.rmaTrackingDraft };
        draft[rmaId] = event.target.value;
        this.rmaTrackingDraft = draft;
    }

    handleRmaTrackingEdit(event) {
        const rmaId = event.currentTarget.dataset.rmaId;
        const editMode = { ...this.rmaTrackingEditMode };
        editMode[rmaId] = true;
        this.rmaTrackingEditMode = editMode;
    }

    async handleRmaTrackingSave(event) {
        const rmaId = event.currentTarget.dataset.rmaId;
        const value = this.rmaTrackingDraft[rmaId] !== undefined
            ? this.rmaTrackingDraft[rmaId]
            : (this.rmaItems.find(r => r.rmaId === rmaId) || {}).engineerRmaTracking || '';
        const saving = { ...this.rmaTrackingSaving };
        saving[rmaId] = true;
        this.rmaTrackingSaving = saving;
        try {
            await updateEngineerRmaTracking({ rmaId, trackingNumber: value });
            this.rmaItems = this.rmaItems.map(r =>
                r.rmaId === rmaId ? { ...r, engineerRmaTracking: value } : r
            );
            const draft = { ...this.rmaTrackingDraft };
            delete draft[rmaId];
            this.rmaTrackingDraft = draft;
            const editMode = { ...this.rmaTrackingEditMode };
            delete editMode[rmaId];
            this.rmaTrackingEditMode = editMode;
            this.showToast('Saved', 'Engineer RMA tracking number updated.', 'success');
        } catch (error) {
            this.showToast('Unable to save', this.reduceError(error), 'error');
        } finally {
            const saving2 = { ...this.rmaTrackingSaving };
            delete saving2[rmaId];
            this.rmaTrackingSaving = saving2;
        }
    }

    handleOpenRma(event) {
        const rmaId = event.currentTarget.dataset.recordId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: rmaId,
                actionName: 'view'
            }
        });
    }

    handleRmaExcludeTrackedChange(event) {
        this.rmaExcludeTracked = event.target.checked;
    }

    handleRmaFilterChange(event) {
        const value = event?.detail?.value ?? event?.target?.value ?? '';
        this.rmaSearchInput = value;
        this.safeClearTimeout(this._rmaSearchDebounceTimeout);
        const normalizedValue = (value || '').trim();
        if (!normalizedValue) {
            this.rmaSearchFilter = '';
            return;
        }
        this._rmaSearchDebounceTimeout = this.safeSetTimeout(() => {
            this.rmaSearchFilter = value;
            this._rmaSearchDebounceTimeout = null;
        }, 300);
    }

    handleTabButtonClick(event) {
        const { dataset } = event.currentTarget;
        const tabValue = dataset.sfsTab || dataset.tab;
        if (!tabValue) {
            return;
        }

        if (tabValue === 'manager' && !this.isManager) {
            this.updateActiveTabState('list');
            return;
        }

        this.updateActiveTabState(tabValue);

        const nextScope = this.getDataScopeForTab(tabValue);
        if (this.loadedDataScope !== nextScope) {
            this.historyItems = [];
            this.historyLoaded = false;
            this.loadAppointments({ preserveScroll: true, dataScope: nextScope });
        }
    }

    handleCalendarTabClick() {
        this.updateActiveTabState('calendar');
    }

    handleCalendarTabKeydown(event) {
        const isActivationKey = event.key === 'Enter' || event.key === ' ';
        if (!isActivationKey) {
            return;
        }

        event.preventDefault();
        this.handleCalendarTabClick();
    }

    handleCalendarPrev() {
        const step = this.isTimelineMode ? -1 : -7;
        this.shiftCalendar(step);
    }

    handleCalendarNext() {
        const step = this.isTimelineMode ? 1 : 7;
        this.shiftCalendar(step);
    }

    handleCalendarToday() {
        this.centerCalendarOnToday();

        if (this.isTimelineMode) {
            this._needsCenterOnToday = true;

            this.safeClearTimeout(this._centerTimeout);
            this._centerTimeout = this.safeSetTimeout(() => {
                this.centerTimelineOnTodayColumn();
            }, 0);
        }
    }

    handleCalendarMode(event) {
        const mode = event.target.dataset.mode;
        if (!mode) return;
        this.calendarMode = mode;

        if (!this.timelineStartDate && !this.weekStartDate) {
            this.centerCalendarOnToday();
        } else {
            this.buildCalendarModel();
        }

        if (this.calendarMode === 'timeline') {
            this._needsCenterOnToday = true;
        }
    }

    handleCalendarPanToggle() {
        this.isCalendarPanMode = !this.isCalendarPanMode;

        if (this.isCalendarPanMode) {
            this.resetDragState();
            this.isPressingForDrag = false;
            this._pendingDrag = null;
            this.clearLongPressTimer();
        }
    }

    // ======= TRAY HANDLERS =======

    shouldUseCompactTray() {
        if (typeof window !== 'undefined' && window.matchMedia) {
            return window.matchMedia('(max-width: 768px)').matches;
        }

        return !this.isDesktopFormFactor;
    }

    handleTrayInfoPointer(event) {
        if (event && typeof event.stopPropagation === 'function') {
            event.stopPropagation();
        }
        this.clearLongPressTimer();
        this.isPressingForDrag = false;
        this._pendingDrag = null;
    }

    handleTrayCardInfoClick(event) {
        this.handleTrayInfoPointer(event);

        const workOrderId =
            event && event.currentTarget && event.currentTarget.dataset
                ? event.currentTarget.dataset.woid
                : null;

        if (!workOrderId) {
            return;
        }

        const workOrder = (this.unscheduledWorkOrders || []).find(
            wo => wo.workOrderId === workOrderId
        );

        if (!workOrder) {
            return;
        }

        const detail = this.normalizeWorkOrderDetail(workOrder);

        if (!detail) {
            return;
        }

        this.safeClearTimeout(this._closeTimeout);
        this.isDetailClosing = false;
        this.selectedAbsence = null;
        this.selectedAppointment = detail;
        this.updateSelectedEventStyles();
    }

    navigateToWorkOrderInformation(workOrderId) {
        if (!workOrderId) {
            return;
        }

        try {
            if (this.isDesktopFormFactor) {
                // Hint the lightning record page to show the Information tab.
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: workOrderId,
                        objectApiName: 'WorkOrder',
                        actionName: 'view'
                    },
                    state: {
                        // Some orgs label the primary tab "Information"; when present, this
                        // deep-link lands the user there while still working for custom layouts.
                        tabsetName: 'Information'
                    }
                });
                return;
            }

            // In the mobile app, deep-link directly to the Information tab for consistency with
            // the dispatcher experience shown in the work order tray.
            const infoUrl =
                'com.salesforce.fieldservice://v1/sObject/' +
                workOrderId +
                '/information';
            infoUrl = `com.salesforce.fieldservice://v1/sObject/${workOrderId}/information`;

            // Navigate to the info URL
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: infoUrl
                }
            });

            try {
                // Navigate to the Work Order record page
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: workOrderId,
                        objectApiName: 'WorkOrder',
                        actionName: 'view'
                    }
                });
            } catch (err) {
                const message =
                    (err &&
                        (err.message ||
                            (err.body && err.body.message))) ||
                    'Unable to open the work order details.';

                this.showToast('Navigation failed', message, 'error');
            }
        }
        catch (err) {
                const message =
                    (err &&
                        (err.message ||
                            (err.body && err.body.message))) ||
                    'Unable to open the work order details.';

                this.showToast('Navigation failed', message, 'error');
            }
    }

    createAppointmentFromWorkOrder(workOrderId, isoStart, isoEnd) {
        this.checkOnline();
        if (this.isOffline) {
            this.showToast(
                'Offline',
                'You must be online to schedule an appointment.',
                'warning'
            );
            return;
        }

        const addressSource =
            (this.appointments || []).find(
                appt => appt.workOrderId === workOrderId
            ) ||
            (this.unscheduledWorkOrders || []).find(
                wo => wo.workOrderId === workOrderId
            );

        if (!this.hasScheduleAddress(addressSource)) {
            const cardId =
                (addressSource && (addressSource.cardId || addressSource.appointmentId)) ||
                workOrderId;
            this.showAddressRequiredHelp(cardId);
            this.isLoading = false;
            return;
        }

        this.isLoading = true;

        createAppointmentForWorkOrder({
            workOrderId,
            startDateTimeIso: isoStart,
            endDateTimeIso: isoEnd,
            targetUserId: this.activeUserId
        })
            .then(() => {
                this.showToast(
                    'Appointment created',
                    'A new appointment has been scheduled from this work order.',
                    'success'
                );
                return this.loadAppointments({ preserveScroll: true });
            })
            .then(() => {
                this.handleCalendarToday();
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.debugInfo = {
                    note: 'Error calling createAppointmentForWorkOrder',
                    errorMessage: message
                };
                this.showToast('Error creating appointment', message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    scheduleSelectedVisitPlacement(
        workOrderId,
        isoStart,
        isoEnd,
        visitAppointmentId = null
    ) {
        if (visitAppointmentId) {
            this.rescheduleExistingAppointment(visitAppointmentId, isoStart);
            return;
        }

        this.createAppointmentFromWorkOrder(workOrderId, isoStart, isoEnd);
    }

    rescheduleExistingAppointment(appointmentId, newStart) {
        if (!appointmentId || !newStart) {
            return;
        }

        this.checkOnline();
        if (this.isOffline) {
            this.showToast(
                'Offline',
                'You must be online to reschedule an appointment.',
                'warning'
            );
            return;
        }

        this.isLoading = true;

        rescheduleAppointment({ appointmentId, newStart })
            .then(() => {
                this.showToast(
                    'Appointment updated',
                    'The appointment has been rescheduled.',
                    'success'
                );
                return this.loadAppointments({ preserveScroll: true });
            })
            .then(() => {
                this.handleCalendarToday();
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.debugInfo = {
                    note: 'Error calling rescheduleAppointment',
                    errorMessage: message
                };
                this.showToast('Error updating appointment', message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleUnassignClick(event) {
        event.stopPropagation();
        const id = event.currentTarget.dataset.id;
        this.openUnassignModal(id);
    }

    closeUnassignModal() {
        this.isUnassignModalOpen = false;
        this.unassignTarget = null;
    }

    get unassignModalSubject() {
        if (!this.unassignTarget) {
            return '';
        }

        return this.unassignTarget.subject || 'Service Appointment';
    }

    get unassignModalWorkOrder() {
        if (!this.unassignTarget || !this.unassignTarget.workOrderNumber) {
            return '';
        }

        return `WO # ${this.unassignTarget.workOrderNumber}`;
    }

    confirmUnassignAppointment() {
        if (!this.unassignTarget || !this.unassignTarget.id) {
            return;
        }

        this.checkOnline();
        if (this.isOffline) {
            this.showToast(
                'Offline',
                'You must be online to update an assignment.',
                'warning'
            );
            return;
        }

        this.isLoading = true;
        const appointmentId = this.unassignTarget.id;

        unassignAppointment({ appointmentId })
            .then(() => {
                this.showToast(
                    'Removed from schedule',
                    'The appointment was returned to the scheduling queue.',
                    'success'
                );
                return this.loadAppointments({ preserveScroll: true });
            })
            .then(() => {
                if (this.isCalendarTabActive) {
                    this.handleCalendarToday();
                }
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.debugInfo = {
                    note: 'Error calling unassignAppointment',
                    errorMessage: message
                };
                this.showToast('Error removing assignment', message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
                this.closeUnassignModal();
            });
    }

    getWorkOrderIdFromContext(event) {
        if (!event || !event.currentTarget || !event.currentTarget.dataset) {
            return null;
        }

        let workOrderId = event.currentTarget.dataset.woid;

        // Fallback to appointment lookup when only the appointment id is present
        if (!workOrderId && event.currentTarget.dataset.id) {
            const appt = this.appointments.find(
                a => a.appointmentId === event.currentTarget.dataset.id
            );
            workOrderId = appt ? appt.workOrderId : null;
        }

        return workOrderId;
    }

    openWorkOrderFromActionMenu(appointmentId, workOrderId) {
        if (workOrderId) {
            this.navigateToWorkOrderRecord(workOrderId);
            return;
        }

        if (appointmentId) {
            this.navigateToServiceAppointment(appointmentId, null);
        }
    }

    handleMoreActionsSelect(event) {
        event.stopPropagation();
        const action = event.detail?.action ?? event.detail?.value;
        const appointmentId =
            event.detail?.appointmentId ??
            event.currentTarget?.dataset?.id;
        const workOrderId =
            event.detail?.workOrderId ??
            this.getWorkOrderIdFromContext(event);

        if (action === 'openInApp') {
            this.openWorkOrderFromActionMenu(appointmentId, workOrderId);
            return;
        }

        if (!workOrderId) {
            return;
        }

        if (action === 'requestTransfer') {
            this.openRescheduleModal(workOrderId);
        } else if (action === 'submitCustomRequest') {
            this.openCustomRequestModal(workOrderId);
        } else if (action === 'markWaitingForPo') {
            this.markWaitingForPo(workOrderId);
        } else if (action === 'cancelWorkOrder') {
            this.openCancelModal(workOrderId);
        } else if (action === 'readyForClose') {
            this.openReadyForCloseModal(workOrderId);
        } else if (action === 'unassign') {
            this.openUnassignModal(appointmentId);
        } else if (action === 'viewDeletedLineItems') {
            this.openDeletedWoliModal(workOrderId);
        }
    }

    handleHistoryOpenInApp(event) {
        const recordId = event.currentTarget.dataset.recordId;
        const recordType = event.currentTarget.dataset.recordType;

        if (!recordId) {
            return;
        }

        if (recordType === 'opportunity') {
            this.navigateToOpportunityRecord(recordId);
        } else {
            this.navigateToWorkOrderRecord(recordId);
        }
    }

    handleHistoryFilterChange(event) {
        const value = event?.detail?.value ?? event?.target?.value ?? '';
        this.historySearchInput = value;

        this.safeClearTimeout(this._historySearchDebounceTimeout);

        const normalizedValue = (value || '').trim();
        if (!normalizedValue) {
            this.historySearchFilter = '';
            return;
        }

        this._historySearchDebounceTimeout = this.safeSetTimeout(() => {
            this.historySearchFilter = value;
            this._historySearchDebounceTimeout = null;
        }, this.historySearchDebounceMs);
    }

    handleLoadHistory() {
        if (this.isHistoryLoading || this.isOffline) {
            return;
        }

        this.isHistoryLoading = true;
        getHistoryItems({ targetUserId: this.activeUserId })
            .then(result => {
                this.historyItems = result || [];
                this.historyLoaded = true;
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.showToast('Error loading history', message, 'error');
            })
            .finally(() => {
                this.isHistoryLoading = false;
            });
    }

    openUnassignModal(appointmentId) {
        if (!appointmentId) {
            return;
        }

        const targetAppt = this.appointments.find(
            appt => appt.appointmentId === appointmentId
        );

        this.unassignTarget = targetAppt
            ? {
                  id: appointmentId,
                  subject: targetAppt.subject,
                  workOrderNumber: targetAppt.workOrderNumber
              }
            : { id: appointmentId };

        this.isUnassignModalOpen = true;
    }

    openRescheduleModal(workOrderId) {
        this.isRescheduleModalOpen = true;
        this.rescheduleLoading = true;
        this.rescheduleOptions = [];
        this.rescheduleSelection = null;
        this.rescheduleWorkOrderId = workOrderId;

        getTerritoryResources({ workOrderId })
            .then(options => {
                const optionList = (options || [])
                    .filter(opt => opt.userId)
                    .map(opt => {
                        return {
                            label: opt.name,
                            value: opt.userId
                        };
                    });

                this.rescheduleOptions = optionList;

                if (this.rescheduleOptions.length) {
                    this.rescheduleSelection = this.rescheduleOptions[0].value;
                } else {
                    this.showToast(
                        'No technicians available',
                        'No active resources with linked users were found for this work order territory.',
                        'warning'
                    );
                }
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.showToast('Unable to load resources', message, 'error');
            })
            .finally(() => {
                this.rescheduleLoading = false;
            });
    }

    closeRescheduleModal() {
        this.isRescheduleModalOpen = false;
        this.rescheduleWorkOrderId = null;
        this.rescheduleOptions = [];
        this.rescheduleSelection = null;
        this.rescheduleLoading = false;
    }

    handleRescheduleSelection(event) {
        this.rescheduleSelection = event.detail.value;
    }

    submitRescheduleRequest() {
        if (!this.rescheduleWorkOrderId || !this.rescheduleSelection) {
            return;
        }

        this.rescheduleLoading = true;

        createEngineerTransferRequest({
            workOrderId: this.rescheduleWorkOrderId,
            targetUserId: this.rescheduleSelection
        })
            .then(() => {
                this.showToast(
                    'Transfer request sent',
                    'The selected technician will review the transfer request.',
                    'success'
                );
                this.closeRescheduleModal();
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.showToast('Error requesting transfer', message, 'error');
            })
            .finally(() => {
                this.rescheduleLoading = false;
            });
    }

    handleAcceptTransferRequest(event) {
        const requestId = event.currentTarget.dataset.id;
        if (!requestId) {
            return;
        }

        this.isLoading = true;

        acceptEngineerTransferRequest({
            transferRequestId: requestId,
            targetOwnerId: this.activeUserId
        })
            .then(() => {
                this.showToast(
                    'Transfer accepted',
                    'The work order has been moved to your scheduling queue.',
                    'success'
                );
                return this.loadAppointments({ preserveScroll: true });
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.showToast('Unable to accept transfer', message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    openRejectModal(event) {
        const requestId = event.currentTarget.dataset.id;
        if (!requestId) {
            return;
        }

        this.rejectRequestId = requestId;
        this.rejectReason = '';
        this.isRejectModalOpen = true;
    }

    closeRejectModal() {
        this.isRejectModalOpen = false;
        this.rejectReason = '';
        this.rejectRequestId = null;
    }

    handleRejectReasonChange(event) {
        this.rejectReason = event.target.value;
    }

    get rejectSubmitDisabled() {
        return this.isLoading || !this.rejectReason;
    }

    submitRejectRequest() {
        if (!this.rejectRequestId || !this.rejectReason) {
            return;
        }

        this.isLoading = true;

        rejectEngineerTransferRequest({
            transferRequestId: this.rejectRequestId,
            reason: this.rejectReason
        })
            .then(() => {
                this.showToast(
                    'Transfer rejected',
                    'The requester will be notified of the rejection reason.',
                    'success'
                );
                this.transferRequests = (this.transferRequests || []).filter(
                    req => req.transferRequestId !== this.rejectRequestId
                );
                this.closeRejectModal();
                return this.loadAppointments({ preserveScroll: true });
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.showToast('Unable to reject transfer', message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    openCancelModal(workOrderId) {
        if (!workOrderId) {
            return;
        }

        this.cancelWorkOrderId = workOrderId;
        this.cancelReason = '';
        this.isCancelModalOpen = true;
    }

    closeCancelModal() {
        this.isCancelModalOpen = false;
        this.cancelReason = '';
        this.cancelWorkOrderId = null;
    }

    handleCancelReasonChange(event) {
        this.cancelReason = event.target.value;
    }

    get cancelSubmitDisabled() {
        return this.isLoading || !this.cancelReason || !this.cancelReason.trim();
    }

    submitCancelWorkOrder() {
        if (!this.cancelWorkOrderId || !this.cancelReason) {
            return;
        }

        if (this.isOffline) {
            this.showToast(
                'Offline',
                'You must be online to cancel a work order.',
                'warning'
            );
            return;
        }

        this.isLoading = true;

        cancelWorkOrder({
            workOrderId: this.cancelWorkOrderId,
            reason: this.cancelReason
        })
            .then(() => {
                this.showToast(
                    'Work order canceled',
                    'The work order was canceled and the reason was saved.',
                    'success'
                );
                this.closeCancelModal();
                return this.loadAppointments({ preserveScroll: true });
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.showToast('Unable to cancel work order', message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    openReadyForCloseModal(workOrderId) {
        if (!workOrderId) {
            return;
        }

        if (!this.isDesktopFormFactor) {
            this.launchReadyForCloseFlow(workOrderId);
            return;
        }

        this.readyForCloseWorkOrderId = workOrderId;
        this.readyForCloseNotes = '';
        this.isReadyForCloseModalOpen = true;
    }

    closeReadyForCloseModal() {
        this.isReadyForCloseModalOpen = false;
        this.readyForCloseNotes = '';
        this.readyForCloseWorkOrderId = null;
    }

    handleReadyForCloseNotesChange(event) {
        this.readyForCloseNotes = event.target.value;
    }

    get readyForCloseSubmitDisabled() {
        return this.isLoading;
    }

    submitReadyForClose() {
        if (!this.readyForCloseWorkOrderId) {
            return;
        }

        if (this.isOffline) {
            this.showToast(
                'Offline',
                'You must be online to update the work order status.',
                'warning'
            );
            return;
        }

        this.isLoading = true;

        markWorkOrderReadyForClose({
            workOrderId: this.readyForCloseWorkOrderId,
            notes: this.readyForCloseNotes
        })
            .then(() => {
                this.showToast(
                    'Status updated',
                    'Work order marked as Ready for Close.',
                    'success'
                );
                this.closeReadyForCloseModal();
                return this.loadAppointments({ preserveScroll: true });
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.debugInfo = {
                    note: 'Error calling markWorkOrderReadyForClose',
                    errorMessage: message
                };
                this.showToast('Error updating status', message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    openCustomRequestModal(workOrderId) {
        if (!workOrderId) {
            return;
        }

        this.customRequestWorkOrderId = workOrderId;
        this.customRequestNotes = '';
        this.isCustomRequestModalOpen = true;
    }

    closeCustomRequestModal() {
        this.isCustomRequestModalOpen = false;
        this.customRequestNotes = '';
        this.customRequestWorkOrderId = null;
    }

    handleCustomRequestNotesChange(event) {
        this.customRequestNotes = event.target.value;
    }

    get customRequestSubmitDisabled() {
        return this.isLoading || !this.customRequestNotes || !this.customRequestNotes.trim();
    }

    submitCustomRequest() {
        if (!this.customRequestWorkOrderId || !this.customRequestNotes) {
            return;
        }

        if (this.isOffline) {
            this.showToast(
                'Offline',
                'You must be online to submit a custom request.',
                'warning'
            );
            return;
        }

        this.isLoading = true;

        submitCustomWorkOrderRequest({
            workOrderId: this.customRequestWorkOrderId,
            notes: this.customRequestNotes
        })
            .then(() => {
                this.showToast(
                    'Request submitted',
                    'Work order marked as Update Needed.',
                    'success'
                );
                this.closeCustomRequestModal();
                return this.loadAppointments({ preserveScroll: true });
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.showToast('Error submitting request', message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // --- Mark Items for Return ---

    get markForReturnCheckboxOptions() {
        return (this.markForReturnLineItems || []).map(item => {
            let label = item.partName || 'Unknown Part';
            if (item.serialNumber) {
                label += ` (Serial: ${item.serialNumber})`;
            }
            return { value: item.lineItemId, label };
        });
    }

    get hasMarkForReturnItems() {
        return (this.markForReturnLineItems || []).length > 0;
    }

    get isMarkForReturnStep1() {
        return this.markForReturnStep === 1;
    }

    get isMarkForReturnStep2() {
        return this.markForReturnStep === 2;
    }

    get markForReturnNextDisabled() {
        return (this.markForReturnSelectedIds || []).length === 0;
    }

    get markForReturnSelectedItems() {
        const selectedSet = new Set(this.markForReturnSelectedIds || []);
        return (this.markForReturnLineItems || [])
            .filter(item => selectedSet.has(item.lineItemId))
            .map(item => {
                let checkboxLabel = item.partName || 'Unknown Part';
                if (item.serialNumber) {
                    checkboxLabel += ` (Serial: ${item.serialNumber})`;
                }
                return { ...item, checkboxLabel };
            });
    }

    get markForReturnSubmitDisabled() {
        if (this.isLoading) return true;
        const items = this.markForReturnSelectedItems;
        if (!items.length) return true;
        return items.some(item => !item.reason || !item.reason.trim());
    }

    handleMarkItemsForReturn(event) {
        const workOrderId = event.currentTarget.dataset.woid;
        if (!workOrderId) return;

        if (this.isOffline) {
            this.showToast('Offline', 'You must be online to mark items for return.', 'warning');
            return;
        }

        this.markForReturnWorkOrderId = workOrderId;
        this.markForReturnStep = 1;
        this.markForReturnLineItems = [];
        this.markForReturnSelectedIds = [];
        this.isMarkForReturnLoading = true;
        this.isMarkForReturnModalOpen = true;

        getWorkOrderLineItemsForReturn({ workOrderId })
            .then(result => {
                this.markForReturnLineItems = (result || []).map(item => ({
                    ...item,
                    reason: ''
                }));
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.showToast('Error loading line items', message, 'error');
                this.closeMarkForReturnModal();
            })
            .finally(() => {
                this.isMarkForReturnLoading = false;
            });
    }

    closeMarkForReturnModal() {
        this.isMarkForReturnModalOpen = false;
        this.markForReturnWorkOrderId = null;
        this.markForReturnStep = 1;
        this.markForReturnLineItems = [];
        this.markForReturnSelectedIds = [];
    }

    openDeletedWoliModal(workOrderId) {
        if (!workOrderId) {
            return;
        }

        if (this.isOffline) {
            this.showToast('Offline', 'You must be online to view deleted line items.', 'warning');
            return;
        }

        this.deletedWoliWorkOrderId = workOrderId;
        this.deletedWoliItems = [];
        this.deletedWoliSelectedIds = [];
        this.isDeletedWoliLoading = true;
        this.isDeletedWoliModalOpen = true;

        getDeletedWorkOrderLineItems({ workOrderId })
            .then(result => {
                this.deletedWoliItems = result || [];
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.showToast('Error loading deleted line items', message, 'error');
                this.closeDeletedWoliModal();
            })
            .finally(() => {
                this.isDeletedWoliLoading = false;
            });
    }

    closeDeletedWoliModal() {
        this.isDeletedWoliModalOpen = false;
        this.deletedWoliWorkOrderId = null;
        this.deletedWoliItems = [];
        this.deletedWoliSelectedIds = [];
    }

    handleDeletedWoliSelectionChange(event) {
        this.deletedWoliSelectedIds = event.detail.value;
    }

    submitRestoreDeletedWolis() {
        if (!this.deletedWoliWorkOrderId || !this.deletedWoliSelectedIds.length) {
            return;
        }

        if (this.isOffline) {
            this.showToast('Offline', 'You must be online to restore line items.', 'warning');
            return;
        }

        this.isLoading = true;

        undeleteWorkOrderLineItems({ lineItemIds: this.deletedWoliSelectedIds })
            .then(() => {
                this.showToast(
                    'Line items restored',
                    `${this.deletedWoliSelectedIds.length} line item(s) have been restored to the work order.`,
                    'success'
                );
                this.closeDeletedWoliModal();
                return this.loadAppointments({ preserveScroll: true });
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.showToast('Error restoring line items', message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    get hasDeletedWoliItems() {
        return (this.deletedWoliItems || []).length > 0;
    }

    get deletedWoliCheckboxOptions() {
        return (this.deletedWoliItems || []).map(item => {
            const label = [
                item.partName || item.description || 'Unknown Part',
                item.lineType ? `[${item.lineType}]` : null,
                item.quantity != null ? `Qty: ${item.quantity}` : null,
                item.serialNumber ? `S/N: ${item.serialNumber}` : null
            ].filter(Boolean).join(' · ');
            return { value: item.lineItemId, label };
        });
    }

    get restoreWoliDisabled() {
        return this.isLoading || !(this.deletedWoliSelectedIds || []).length;
    }

    handleMarkForReturnSelectionChange(event) {
        this.markForReturnSelectedIds = event.detail.value;
    }

    handleMarkForReturnNext() {
        if ((this.markForReturnSelectedIds || []).length === 0) return;
        this.markForReturnStep = 2;
    }

    handleMarkForReturnBack() {
        this.markForReturnStep = 1;
    }

    handleMarkForReturnReasonChange(event) {
        const lineItemId = event.currentTarget.dataset.lineitemid;
        const reason = event.target.value;
        this.markForReturnLineItems = this.markForReturnLineItems.map(item =>
            item.lineItemId === lineItemId ? { ...item, reason } : item
        );
    }

    submitMarkForReturn() {
        if (!this.markForReturnWorkOrderId) return;

        if (this.isOffline) {
            this.showToast('Offline', 'You must be online to submit this request.', 'warning');
            return;
        }

        const selectedItems = this.markForReturnSelectedItems;
        if (!selectedItems.length) return;

        if (selectedItems.some(item => !item.reason || !item.reason.trim())) {
            this.showToast('Missing reason', 'Please provide a reason for each selected item.', 'warning');
            return;
        }

        this.isLoading = true;

        const itemsPayload = selectedItems.map(item => ({
            partName: item.partName,
            serialNumber: item.serialNumber,
            reason: item.reason.trim()
        }));

        markWorkOrderItemsForReturn({
            workOrderId: this.markForReturnWorkOrderId,
            itemsJson: JSON.stringify(itemsPayload)
        })
            .then(() => {
                this.showToast('Items marked for return', 'Work order marked as Update Needed.', 'success');
                this.closeMarkForReturnModal();
                return this.loadAppointments({ preserveScroll: true });
            })
            .catch(error => {
                const message = this.reduceError(error);
                this.showToast('Error marking items for return', message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    launchReadyForCloseFlow(workOrderId) {
        if (!workOrderId) {
            return;
        }

        this.checkOnline();
        if (this.isOffline) {
            this.showToast(
                'Offline',
                'You must be online to launch the Ready for Close flow.',
                'warning'
            );
            return;
        }

        if (!this.updateCommentsFlowApiName) {
            this.showToast(
                'Flow unavailable',
                'The update comments flow is not configured.',
                'error'
            );
            return;
        }

        const deepLink = `com.salesforce.fieldservice://v1/sObject/${workOrderId}/flow/${this.updateCommentsFlowApiName}`;

        try {
            this.navigateToUrl(deepLink);
        } catch (error) {
            console.error('Unable to open Ready for Close flow', error);
            this.showToast(
                'Ready for Close unavailable',
                'We were unable to open the Ready for Close flow. Please try again.',
                'error'
            );
        }
    }

    normalizeTransferRequest(req) {
        const clone = { ...req };
        clone.fullAddress = this.composeFullAddress({
            street: req.street,
            city: req.city,
            state: req.state,
            postalCode: req.postalCode,
            country: req.country
        });
        clone.hasFullAddress = this.hasStreetValue(req);

        const statusMeta = this.getTransferStatusMeta(req);
        clone.statusLabel = statusMeta.statusLabel;
        clone.statusClass = statusMeta.statusClass;
        clone.rejectionReason = req.rejectionReason;

        return clone;
    }

    getTransferStatusMeta(req) {
        if (req.acceptedOn) {
            return {
                statusLabel: 'Accepted',
                statusClass: 'sfs-status sfs-status_success'
            };
        }

        if (req.rejectedOn) {
            return {
                statusLabel: 'Rejected',
                statusClass: 'sfs-status sfs-status_error'
            };
        }

        return {
            statusLabel: 'Pending',
            statusClass: 'sfs-status sfs-status_pending'
        };
    }

    getEventTypeClass(workTypeName) {
        const meta = this.getEventTypeMeta(workTypeName);
        return meta.className;
    }

    getEventTypeMeta(workTypeName) {
        if (!workTypeName || typeof workTypeName !== 'string') {
            return { className: 'sfs-event-default', symbol: '' };
        }
        const name = workTypeName.toLowerCase();

        if (name.includes('parts sale')) {
            return { className: 'sfs-event-parts-sale', symbol: '🧩' };
        }
        if (name.includes('probe sale')) {
            return { className: 'sfs-event-probe-sale', symbol: '🔬' };
        }
        if (name.includes('probe repair')) {
            return { className: 'sfs-event-probe-repair', symbol: '🛠️' };
        }
        if (
            name.includes('preventative maintenance') ||
            name.includes('preventive maintenance')
        ) {
            return {
                className: 'sfs-event-preventative-maintenance',
                symbol: '🛡️'
            };
        }
        if (name.includes('break') || name.includes('fix')) {
            return { className: 'sfs-event-breakfix', symbol: '' };
        }
        if (
            name.includes('pm') ||
            name.includes('preventive') ||
            name.includes('preventative')
        ) {
            return { className: 'sfs-event-pm', symbol: '' };
        }
        if (name.includes('install')) {
            return { className: 'sfs-event-install', symbol: '' };
        }
        return { className: 'sfs-event-default', symbol: '' };
    }

    // ======= UTIL =======

    registerGlobalErrorHandlers() {
        if (
            this._hasRegisteredErrorHandlers ||
            !this.hasWindow ||
            typeof window.addEventListener !== 'function'
        ) {
            return;
        }

        this._boundOnGlobalError = event => this.onGlobalError(event);
        this._boundOnUnhandledRejection = event =>
            this.onUnhandledRejection(event);

        window.addEventListener('error', this._boundOnGlobalError);
        window.addEventListener(
            'unhandledrejection',
            this._boundOnUnhandledRejection
        );

        this._hasRegisteredErrorHandlers = true;
    }

    unregisterGlobalErrorHandlers() {
        if (!this._hasRegisteredErrorHandlers || !this.hasWindow) {
            return;
        }

        if (
            typeof window.removeEventListener === 'function' &&
            this._boundOnGlobalError
        ) {
            window.removeEventListener('error', this._boundOnGlobalError);
        }

        if (
            typeof window.removeEventListener === 'function' &&
            this._boundOnUnhandledRejection
        ) {
            window.removeEventListener(
                'unhandledrejection',
                this._boundOnUnhandledRejection
            );
        }

        this._hasRegisteredErrorHandlers = false;
        this._boundOnGlobalError = null;
        this._boundOnUnhandledRejection = null;
    }

    onGlobalError(event) {
        if (!event) {
            return;
        }

        if (typeof event.preventDefault === 'function') {
            event.preventDefault();
        }

        const error =
            event.error ||
            new Error(
                event.message || 'Script error occurred before error object.'
            );

        this.captureError(error, 'window.onerror');
    }

    onUnhandledRejection(event) {
        if (!event) {
            return;
        }

        if (typeof event.preventDefault === 'function') {
            event.preventDefault();
        }

        const reason = event.reason || event.detail?.reason;
        const error =
            reason instanceof Error
                ? reason
                : new Error(
                      reason || 'Unhandled promise rejection with no reason'
                  );

        this.captureError(error, 'window.unhandledrejection');
    }

    get hasWindow() {
        return typeof window !== 'undefined';
    }

    safeSetTimeout(callback, delay) {
        if (!this.hasWindow || typeof window.setTimeout !== 'function') {
            return null;
        }
        return window.setTimeout(callback, delay);
    }

    safeClearTimeout(handle) {
        if (this.hasWindow && typeof window.clearTimeout === 'function') {
            window.clearTimeout(handle);
        }
    }

    captureError(error, context = '') {
        if (typeof console !== 'undefined' && typeof console.error === 'function') {
            console.error('[fslHello]', context, error);
        }

        const message =
            (error && (error.message || error.body?.message)) || 'Unknown error';

        this.debugInfo = {
            ...this.debugInfo,
            lastError: {
                context,
                message,
                stack: error?.stack || null
            }
        };
    }

    reduceError(error) {
        let message = 'Unknown error';
        if (error && Array.isArray(error.body)) {
            message = error.body.map(e => e.message).join(', ');
        } else if (error && error.body && error.body.message) {
            message = error.body.message;
        } else if (error && error.message) {
            message = error.message;
        }
        return message;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}
