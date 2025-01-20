// CalendarDateSelect version 1.10.0 - a prototype based date picker
// Questions, comments, bugs? - email the Author - Tim Harper <"timseeharper@gmail.seeom".gsub("see", "c")> 
if (typeof Prototype == 'undefined') alert("CalendarDateSelect Error: Prototype could not be found. Please make sure that your application's layout includes prototype.js (.g. <%= javascript_include_tag :defaults %>) *before* it includes calendar_date_select.js (.g. <%= calendar_date_select_includes %>).");
if (Prototype.Version < "1.6") alert("Prototype 1.6.0 is required.  If using earlier version of prototype, please use calendar_date_select version 1.8.3");

Element.addMethods({
  purgeChildren: function(element) { $A(element.childNodes).each(function(e){$(e).remove();}); },
  build: function(element, type, options, style) {
    var newElement = Element.build(type, options, style);
    element.appendChild(newElement);
    return newElement;
  }
});

Element.build = function(type, options, style)
{
  var e = $(document.createElement(type));
  $H(options).each(function(pair) { eval("e." + pair.key + " = pair.value" ); });
  if (style) 
    $H(style).each(function(pair) { eval("e.style." + pair.key + " = pair.value" ); });
  return e;
};
nil = null;

Date.one_day = 24*60*60*1000;
Date.weekdays = $w("S M T W T F S");
Date.first_day_of_week = 0;
Date.months = $w("January February March April May June July August September October November December" );
Date.padded2 = function(hour) { var padded2 = parseInt(hour, 10); if (hour < 10) padded2 = "0" + padded2; return padded2; }
Date.prototype.getPaddedMinutes = function() { return Date.padded2(this.getMinutes()); }
Date.prototype.getAMPMHour = function() { var hour = this.getHours(); return (hour == 0) ? 12 : (hour > 12 ? hour - 12 : hour ) }
Date.prototype.getAMPM = function() { return (this.getHours() < 12) ? "AM" : "PM"; }
Date.prototype.stripTime = function() { return new Date(this.getFullYear(), this.getMonth(), this.getDate());};
Date.prototype.daysDistance = function(compare_date) { return Math.round((compare_date - this) / Date.one_day); };
Date.prototype.toFormattedString = function(include_time){
  var hour, str;
  str = Date.months[this.getMonth()] + " " + this.getDate() + ", " + this.getFullYear();
  
  if (include_time) { hour = this.getHours(); str += " " + this.getAMPMHour() + ":" + this.getPaddedMinutes() + " " + this.getAMPM() }
  return str;
}
Date.parseFormattedString = function(string) { return new Date(string);}
Math.floor_to_interval = function(n, i) { return Math.floor(n/i) * i;}
window.f_height = function() { return( [window.innerHeight ? window.innerHeight : null, document.documentElement ? document.documentElement.clientHeight : null, document.body ? document.body.clientHeight : null].select(function(x){return x>0}).first()||0); }
/**
 * Retrieves the current vertical scroll position of the window.
 * @returns {number} The number of pixels the document has been scrolled vertically.
 */
window.f_scrollTop = function() { return ([window.pageYOffset ? window.pageYOffset : null, document.documentElement ? document.documentElement.scrollTop : null, document.body ? document.body.scrollTop : null].select(function(x){return x>0}).first()||0 ); }

_translations = {
  "OK": "OK",
  "Now": "Now",
  "Today": "Today"
}
SelectBox = Class.create();
SelectBox.prototype = {
  /**
   * Initializes a select element with the given options and populates it with values.
   * @param {HTMLElement|string} parent_element - The parent element or selector where the select element will be created.
   * @param {Array|Object} values - The values to populate the select element with.
   * @param {Object} html_options - HTML attributes to be applied to the select element.
   * @param {Object} style_options - CSS styles to be applied to the select element.
   * @returns {jQuery} The created and populated select element as a jQuery object.
   */
  initialize: function(parent_element, values, html_options, style_options) {
    this.element = $(parent_element).build("select", html_options, style_options);
    this.populate(values);
  },
  populate: function(values) {
    this.element.purgeChildren();
    /**
     * Populates a select element with options based on the provided values.
     * @param {Array} values - An array of values or key-value pairs to create options from.
     * @returns {undefined} This method does not return a value.
     */
    var that = this; $A(values).each(function(pair) { if (typeof(pair)!="object") {pair = [pair, pair]}; that.element.build("option", { value: pair[1], innerHTML: pair[0]}) });
  },
  /**
   * Sets the selected option of a select element based on a given value.
   * @param {string|number} value - The value to match against the options' values.
   * @returns {boolean} Returns true if a matching option was found and selected, false otherwise.
   */
  setValue: function(value) {
    var e = this.element;
    var matched = false;
    $R(0, e.options.length - 1 ).each(function(i) { if(e.options[i].value==value.toString()) {e.selectedIndex = i; matched = true;}; } );
    return matched;
  },
  getValue: function() { return $F(this.element)}
}
CalendarDateSelect = Class.create();
CalendarDateSelect.prototype = {
  /**
   * Initializes the calendar date select component.
   * @param {Element|string} target_element - The target element or its ID where the calendar will be attached.
   * @param {Object} options - Configuration options for the calendar.
   * @param {boolean} [options.embedded=false] - Whether the calendar is embedded in the page.
   * @param {Element} [options.popup] - The element to use as a popup container.
   * @param {boolean} [options.time=false] - Whether to include time selection.
   * @param {boolean} [options.buttons=true] - Whether to show action buttons.
   * @param {number} [options.year_range=10] - The range of years to display.
   * @param {Element} [options.calendar_div] - The element to use as the calendar container.
   * @param {boolean} [options.close_on_click] - Whether to close the calendar on click outside.
   * @param {number} [options.minute_interval=5] - The interval for minute selection.
   * @param {Element} [options.popup_by] - The element to position the popup by.
   * @param {string} [options.month_year="dropdowns"] - The format for month and year selection.
   * @param {Function} [options.onchange] - The onchange event handler.
   * @param {Function} [options.valid_date_check] - A function to validate dates.
   * @returns {boolean} Returns false if the target element is not found, otherwise undefined.
   */
  initialize: function(target_element, options) {
    this.target_element = $(target_element); // make sure it's an element, not a string
    if (!this.target_element) { alert("Target element " + target_element + " not found!"); return false;}
    if (down = this.target_element.down("INPUT")) this.target_element = down;
    
    this.target_element.calendar_date_select = this;
    this.last_click_at = 0;
    // initialize the date control
    this.options = $H({
      embedded: false,
      popup: nil,
      time: false,
      buttons: true,
      year_range: 10,
      calendar_div: nil,
      close_on_click: nil,
      minute_interval: 5,
      popup_by: this.target_element,
      month_year: "dropdowns",
      onchange: this.target_element.onchange,
      valid_date_check: nil
    }).merge(options || {});
    
    this.selection_made = $F(this.target_element).strip()!=="";
    this.use_time = this.options.get("time");
    
    this.callback("before_show")
    this.calendar_div = $(this.options.get("calendar_div"));
    
    this.parseDate();
    
    // by default, stick it by the target element (if embedded, that's where we'll want it to show up)
    if (this.calendar_div == nil) { this.calendar_div = $( this.options.get("embedded") ? this.target_element.parentNode : document.body ).build('div'); }
    if (!this.options.get("embedded")) this.calendar_div.setStyle( { position:"absolute", visibility: "hidden", left:0, top:0 } )
    
    this.calendar_div.addClassName("calendar_date_select");
    
    if (this.options.get("embedded")) this.options.set("close_on_click", false);
    // logic for close on click
    if (this.options.get("close_on_click")===nil )
    {
      if (this.options.get("time"))
        this.options.set("close_on_click", false);
      else
        this.options.set("close_on_click", true);
    }
    
    // set the click handler to check if a user has clicked away from the document
    if(!this.options.get("embedded")) {
      Event.observe(document, "mousedown", this.closeIfClickedOut_handler = this.closeIfClickedOut.bindAsEventListener(this));
      Event.observe(document, "keypress", this.keyPress_handler = this.keyPress.bindAsEventListener(this));
    }
    
    this.init();
    if(!this.options.get("embedded")) { this.positionCalendarDiv() };
    this.callback("after_show")
  },
  positionCalendarDiv: function() {
    var above = false;
    var c_pos = this.calendar_div.cumulativeOffset(), c_left = c_pos[0], c_top = c_pos[1], c_dim = this.calendar_div.getDimensions(), c_height = c_dim.height, c_width = c_dim.width; 
    var w_top = window.f_scrollTop(), w_height = window.f_height();
    var e_dim = $(this.options.get("popup_by")).cumulativeOffset(), e_top = e_dim[1], e_left = e_dim[0], e_height = $(this.options.get("popup_by")).getDimensions().height, e_bottom = e_top + e_height;
    
    if ( (( e_bottom + c_height ) > (w_top + w_height)) && ( e_bottom - c_height > w_top )) above = true;
    var left_px = e_left.toString() + "px", top_px = (above ? (e_top - c_height ) : ( e_top + e_height )).toString() + "px";
    
    this.calendar_div.style.left = left_px;  this.calendar_div.style.top = top_px;
    
    this.calendar_div.setStyle({visibility:""});
    
    // draw an iframe behind the calendar -- ugly hack to make IE 6 happy
    if(navigator.appName=="Microsoft Internet Explorer") this.iframe = $(document.body).build("iframe", {className: "ie6_blocker"}, { left: left_px, top: top_px, height: c_height.toString()+"px", width: c_width.toString()+"px", border: "0px"})
  },
  /**
   * Initializes the calendar component by creating necessary DOM elements and setting up the calendar structure.
   * This method creates divs for different parts of the calendar, initializes the header, buttons, and calendar grid,
   * updates the footer, refreshes the calendar, and sets the time usage based on the configuration.
   * @returns {void} This method does not return a value.
   */
  init: function() {
    var that = this;
    // create the divs
    $w("top header body buttons footer bottom").each(function(name) {
      eval("var " + name + "_div = that." + name + "_div = that.calendar_div.build('div', { className: 'cds_"+name+"' }, { clear: 'left'} ); ");
    });
    
    this.initHeaderDiv();
    this.initButtonsDiv();
    this.initCalendarGrid();
    this.updateFooter("&nbsp;");
    
    this.refresh();
    this.setUseTime(this.use_time);
  },
  initHeaderDiv: function() {
    var header_div = this.header_div;
    this.close_button = header_div.build("a", { innerHTML: "x", href:"#", onclick:function () { this.close(); return false; }.bindAsEventListener(this), className: "close" });
    this.next_month_button = header_div.build("a", { innerHTML: "&gt;", href:"#", onclick:function () { this.navMonth(this.date.getMonth() + 1 ); return false; }.bindAsEventListener(this), className: "next" });
    this.prev_month_button = header_div.build("a", { innerHTML: "&lt;", href:"#", onclick:function () { this.navMonth(this.date.getMonth() - 1 ); return false; }.bindAsEventListener(this), className: "prev" });
    
    if (this.options.get("month_year")=="dropdowns") {
      this.month_select = new SelectBox(header_div, $R(0,11).map(function(m){return [Date.months[m], m]}), {className: "month", onchange: function () { this.navMonth(this.month_select.getValue()) }.bindAsEventListener(this)}); 
      this.year_select = new SelectBox(header_div, [], {className: "year", onchange: function () { this.navYear(this.year_select.getValue()) }.bindAsEventListener(this)}); 
      this.populateYearRange();
    } else {
      this.month_year_label = header_div.build("span")
    }
  },
  /**
   * Initializes the calendar grid for the date selector.
   * This method creates a table structure representing the calendar,
   * including weekday headers and individual day cells for a 6-week period.
   * It also sets up event handlers for day selection and hover effects.
   * @returns {void} This method does not return a value.
   */
  initCalendarGrid: function() {
    var body_div = this.body_div;
    this.calendar_day_grid = [];
    var days_table = body_div.build("table", { cellPadding: "0px", cellSpacing: "0px", width: "100%" })
    // make the weekdays!
    var weekdays_row = days_table.build("thead").build("tr");
    Date.weekdays.each( function(weekday) { 
      weekdays_row.build("th", {innerHTML: weekday});
    });
    
    var days_tbody = days_table.build("tbody")
    // Make the days!
    var row_number = 0, weekday;
    for(var cell_index = 0; cell_index<42; cell_index++)
    {
      weekday = (cell_index+Date.first_day_of_week ) % 7;
      if ( cell_index % 7==0 ) days_row = days_tbody.build("tr", {className: 'row_'+row_number++});
      (this.calendar_day_grid[cell_index] = days_row.build("td", {
          calendar_date_select: this,
          onmouseover: function () { this.calendar_date_select.dayHover(this); },
          onmouseout: function () { this.calendar_date_select.dayHoverOut(this) },
          onclick: function() { this.calendar_date_select.updateSelectedDate(this, true); },
          className: (weekday==0) || (weekday==6) ? " weekend" : "" //clear the class
        },
        { cursor: "pointer" }
      )).build("div");
      this.calendar_day_grid[cell_index];
    }
  },
  initButtonsDiv: function()
  {
    var buttons_div = this.buttons_div;
    if (this.options.get("time"))
    {
      var blank_time = $A(this.options.get("time")=="mixed" ? [[" - ", ""]] : []);
      buttons_div.build("span", {innerHTML:"@", className: "at_sign"});
      
      var t = new Date();
      this.hour_select = new SelectBox(buttons_div,
        blank_time.concat($R(0,23).map(function(x) {t.setHours(x); return $A([t.getAMPMHour()+ " " + t.getAMPM(),x])} )),
        { 
          calendar_date_select: this, 
          onchange: function() { this.calendar_date_select.updateSelectedDate( { hour: this.value });},
          className: "hour" 
        }
      );
      buttons_div.build("span", {innerHTML:":", className: "seperator"});
      var that = this;
      this.minute_select = new SelectBox(buttons_div,
        blank_time.concat($R(0,59).select(function(x){return (x % that.options.get('minute_interval')==0)}).map(function(x){ return $A([ Date.padded2(x), x]); } ) ),
        { 
          calendar_date_select: this, 
          onchange: function() { this.calendar_date_select.updateSelectedDate( {minute: this.value }) }, 
          className: "minute" 
        }
      );
      
    } else if (! this.options.get("buttons")) buttons_div.remove();
    
    if (this.options.get("buttons")) {
      buttons_div.build("span", {innerHTML: "&nbsp;"});
      if (this.options.get("time")=="mixed" || !this.options.get("time")) b = buttons_div.build("a", {
          innerHTML: _translations["Today"],
          href: "#",
          onclick: function() {this.today(false); return false;}.bindAsEventListener(this)
        });
      
      if (this.options.get("time")=="mixed") buttons_div.build("span", {innerHTML: " | ", className:"button_seperator"})
      
      if (this.options.get("time")) b = buttons_div.build("a", {
        innerHTML: _translations["Now"],
        href: "#",
        onclick: function() {this.today(true); return false}.bindAsEventListener(this)
      });
      
      if (!this.options.get("embedded"))
      {
        buttons_div.build("span", {innerHTML: "&nbsp;"});
        buttons_div.build("a", { innerHTML: _translations["OK"], href: "#", onclick: function() {this.close(); return false;}.bindAsEventListener(this) });
      }
    }
  },
  /**
   * Refreshes the calendar display by updating various components.
   * This method performs a series of refresh operations including:
   * - Refreshing the month and year display
   * - Refreshing the calendar grid
   * - Setting the selected class
   * - Updating the footer
   * @returns {void} This method does not return a value.
   */
  refresh: function ()
  {
    this.refreshMonthYear();
    this.refreshCalendarGrid();
    
    this.setSelectedClass();
    this.updateFooter();
  },
  refreshCalendarGrid: function () {
    this.beginning_date = new Date(this.date).stripTime();
    this.beginning_date.setDate(1);
    this.beginning_date.setHours(12); // Prevent daylight savings time boundaries from showing a duplicate day
    var pre_days = this.beginning_date.getDay() // draw some days before the fact
    if (pre_days < 3) pre_days += 7;
    this.beginning_date.setDate(1 - pre_days + Date.first_day_of_week);
    
    var iterator = new Date(this.beginning_date);
    
    var today = new Date().stripTime();
    var this_month = this.date.getMonth();
    vdc = this.options.get("valid_date_check");
    for (var cell_index = 0;cell_index<42; cell_index++)
    {
      day = iterator.getDate(); month = iterator.getMonth();
      cell = this.calendar_day_grid[cell_index];
      Element.remove(cell.childNodes[0]); div = cell.build("div", {innerHTML:day});
      if (month!=this_month) div.className = "other";
      cell.day = day; cell.month = month; cell.year = iterator.getFullYear();
      if (vdc) { if (vdc(iterator.stripTime())) cell.removeClassName("disabled"); else cell.addClassName("disabled") };
      iterator.setDate( day + 1);
    }
    
    if (this.today_cell) this.today_cell.removeClassName("today");
    
    if ( $R( 0, 42 ).include(days_until = this.beginning_date.daysDistance(today)) ) {
      this.today_cell = this.calendar_day_grid[days_until];
      this.today_cell.addClassName("today");
    }
  },
  /**
   * Refreshes the month and year display in the date picker.
   * This method updates either the dropdown selects or the label
   * based on the current date and option settings.
   * 
   * @returns {undefined} This method does not return a value.
   */
  refreshMonthYear: function() {
    var m = this.date.getMonth();
    var y = this.date.getFullYear();
    // set the month
    if (this.options.get("month_year") == "dropdowns") 
    {
      this.month_select.setValue(m, false);
      
      var e = this.year_select.element; 
      if (this.flexibleYearRange() && (!(this.year_select.setValue(y, false)) || e.selectedIndex <= 1 || e.selectedIndex >= e.options.length - 2 )) this.populateYearRange();
      
      this.year_select.setValue(y);
      
    } else {
      this.month_year_label.update( Date.months[m] + " " + y.toString()  );
    }
  },
  populateYearRange: function() {
    this.year_select.populate(this.yearRange().toArray());
  },
  /**
   * Calculates and returns a range of years based on the current date and configuration options.
   * @returns {Object} A range object representing the calculated year range.
   *                   The range is created using the $R() function, which likely returns
   *                   an object with properties for the start and end of the range.
   */
  yearRange: function() {
    if (!this.flexibleYearRange())
      return $R(this.options.get("year_range")[0], this.options.get("year_range")[1]);
      
    var y = this.date.getFullYear();
    return $R(y - this.options.get("year_range"), y + this.options.get("year_range"));
  },
  flexibleYearRange: function() { return (typeof(this.options.get("year_range")) == "number"); },
  /**
   * Validates if a given year is within the acceptable range
   * @param {number} year - The year to be validated
   * @returns {boolean} True if the year is valid, false otherwise
   */
  validYear: function(year) { if (this.flexibleYearRange()) { return true;} else { return this.yearRange().include(year);}  },
  dayHover: function(element) {
    var hover_date = new Date(this.selected_date);
    hover_date.setYear(element.year); hover_date.setMonth(element.month); hover_date.setDate(element.day);
    this.updateFooter(hover_date.toFormattedString(this.use_time));
  },
  dayHoverOut: function(element) { this.updateFooter(); },
  setSelectedClass: function() {
    if (!this.selection_made) return;
    
    // clear selection
    if (this.selected_cell) this.selected_cell.removeClassName("selected");
    
    if ($R(0,42).include( days_until = this.beginning_date.stripTime().daysDistance(this.selected_date.stripTime()) )) {
      this.selected_cell = this.calendar_day_grid[days_until];
      this.selected_cell.addClassName("selected");
    }
  },
  reparse: function() { this.parseDate(); this.refresh(); },
  dateString: function() {
    return (this.selection_made) ? this.selected_date.toFormattedString(this.use_time) : "&nbsp;";
  },
  /**
   * Parses and validates a date string, setting internal date properties.
   * @param {void} No parameters
   * @returns {void} This method doesn't return a value
   * 
   * @description
   * This method performs the following operations:
   * 1. Strips whitespace from the value of the target element
   * 2. Parses the date string using a custom parsing method
   * 3. Sets the date to today if parsing fails
   * 4. Validates the year and adjusts if necessary
   * 5. Sets the selected date
   * 6. Determines if time information is present
   * 7. Resets the day of the month to 1
   * 
   * @throws {TypeError} May throw a TypeError if date parsing fails
   */
  parseDate: function()
  {
    var value = $F(this.target_element).strip()
    this.date = value=="" ? NaN : Date.parseFormattedString(this.options.get("date") || value);
    if (isNaN(this.date)) this.date = new Date();
    if (!this.validYear(this.date.getFullYear())) this.date.setYear( (this.date.getFullYear() < this.yearRange().start) ? this.yearRange().start : this.yearRange().end);
    this.selected_date = new Date(this.date);
    this.use_time = /[0-9]:[0-9]{2}/.exec(value) ? true : false;
    this.date.setDate(1);
  },
  updateFooter:function(text) { if (!text) text = this.dateString(); this.footer_div.purgeChildren(); this.footer_div.build("span", {innerHTML: text }); },
  /**
   * Updates the selected date based on provided parts or element and handles related UI updates.
   * @param {Object|Element} partsOrElement - Date parts as an object or an element containing date information
   * @param {boolean} via_click - Indicates if the update was triggered by a click event
   * @returns {boolean} False if the update is prevented, undefined otherwise
   */
  updateSelectedDate:function(partsOrElement, via_click) {
    var parts = $H(partsOrElement);
    if ((this.target_element.disabled || this.target_element.readOnly) && this.options.get("popup") != "force") return false;
    if (parts.get("day")) {
      var t_selected_date = this.selected_date, vdc = this.options.get("valid_date_check");
      for (var x = 0; x<=3; x++) t_selected_date.setDate(parts.get("day"));
      t_selected_date.setYear(parts.get("year"));
      t_selected_date.setMonth(parts.get("month"));
      
      if (vdc && ! vdc(t_selected_date.stripTime())) { return false; }
      this.selected_date = t_selected_date;
      this.selection_made = true;
    }
    
    if (!isNaN(parts.get("hour"))) this.selected_date.setHours(parts.get("hour"));
    if (!isNaN(parts.get("minute"))) this.selected_date.setMinutes( Math.floor_to_interval(parts.get("minute"), this.options.get("minute_interval")) );
    if (parts.get("hour") === "" || parts.get("minute") === "") 
      this.setUseTime(false);
    else if (!isNaN(parts.get("hour")) || !isNaN(parts.get("minute")))
      this.setUseTime(true);
    
    this.updateFooter();
    this.setSelectedClass();
    
    if (this.selection_made) this.updateValue();
    if (this.options.get("close_on_click")) { this.close(); }
    if (via_click && !this.options.get("embedded")) {
      if ((new Date() - this.last_click_at) < 333) this.close();
      this.last_click_at = new Date();
    }
  },
  navMonth: function(month) { (target_date = new Date(this.date)).setMonth(month); return (this.navTo(target_date)); },
  /**
   * Navigates to a specific year by updating the date and calling navTo method
   * @param {number} year - The year to navigate to
   * @returns {boolean} Returns the result of calling the navTo method with the new date
   */
  navYear: function(year) { (target_date = new Date(this.date)).setYear(year); return (this.navTo(target_date)); },
  navTo: function(date) {
    if (!this.validYear(date.getFullYear())) return false;
    this.date = date;
    this.date.setDate(1);
    this.refresh();
    this.callback("after_navigate", this.date);
    return true;
  },
  /**
   * Sets the use of time for the date picker based on the provided parameter and options.
   * This method updates the time-related UI elements (hour and minute selects) if applicable.
   * @param {boolean} turn_on - Determines whether to enable time selection
   * @returns {void} This method does not return a value
   */
  setUseTime: function(turn_on) {
    this.use_time = this.options.get("time") && (this.options.get("time")=="mixed" ? turn_on : true) // force use_time to true if time==true && time!="mixed"
    if (this.use_time && this.selected_date) { // only set hour/minute if a date is already selected
      var minute = Math.floor_to_interval(this.selected_date.getMinutes(), this.options.get("minute_interval"));
      var hour = this.selected_date.getHours();
      
      this.hour_select.setValue(hour);
      this.minute_select.setValue(minute)
    } else if (this.options.get("time")=="mixed") {
      this.hour_select.setValue(""); this.minute_select.setValue("");
    }
  },
  updateValue: function() {
    var last_value = this.target_element.value;
    this.target_element.value = this.dateString();
    if (last_value!=this.target_element.value) this.callback("onchange");
  },
  /**
   * Updates the date and refreshes the display.
   * @param {boolean} now - If true, includes hour and minute in the update. If false, hour and minute are set to empty strings.
   * @returns {void} This method does not return a value.
   */
  today: function(now) {
    var d = new Date(); this.date = new Date();
    var o = $H({ day: d.getDate(), month: d.getMonth(), year: d.getFullYear(), hour: d.getHours(), minute: d.getMinutes()});
    if ( ! now ) o = o.merge({hour: "", minute:""}); 
    this.updateSelectedDate(o, true);
    this.refresh();
  },
  close: function() {
    if (this.closed) return false;
    this.callback("before_close");
    this.target_element.calendar_date_select = nil;
    Event.stopObserving(document, "mousedown", this.closeIfClickedOut_handler);
    Event.stopObserving(document, "keypress", this.keyPress_handler);
    this.calendar_div.remove(); this.closed = true;
    if (this.iframe) this.iframe.remove();
    if (this.target_element.type!="hidden") this.target_element.focus();
    this.callback("after_close");
  },
  /**
   * Closes the calendar if the user clicks outside of it.
   * @param {Event} e - The event object representing the click event.
   * @returns {void} This method does not return a value.
   */
  closeIfClickedOut: function(e) {
    if (! $(Event.element(e)).descendantOf(this.calendar_div) ) this.close();
  },
  keyPress: function(e) {
    if (e.keyCode==Event.KEY_ESC) this.close();
  },
  callback: function(name, param) { if (this.options.get(name)) { this.options.get(name).bind(this.target_element)(param); } }
}