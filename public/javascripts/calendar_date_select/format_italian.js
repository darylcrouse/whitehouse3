// Italian Format: 31/12/2000 23:00
// Thanks, Bigonazzi!

/**
 * Converts a Date object to a formatted string representation.
 * @param {boolean} include_time - Whether to include the time in the formatted string.
 * @returns {string} A string representation of the date, optionally including time.
 */
Date.prototype.toFormattedString = function(include_time){
  str = this.getDate() + "/" + (this.getMonth() + 1) + "/" + this.getFullYear();
  if (include_time) { hour=this.getHours(); str += " " + this.getAMPMHour() + ":" + this.getPaddedMinutes() }
  return str;
}

/**
 * Parses a formatted date string into a Date object
 * @param {string} string - The formatted date string to parse
 * @returns {Date} A Date object representing the parsed date and time
 */
Date.parseFormattedString = function (string) {
  var regexp = '([0-9]{1,2})/(([0-9]{1,2})/(([0-9]{4})( ([0-9]{1,2}):([0-9]{2})? *)?)?)?';
  var d = string.match(new RegExp(regexp, "i"));
  if (d==null) return Date.parse(string); // at least give javascript a crack at it.
  var offset = 0;
  var date = new Date(d[5], 0, 1);
  if (d[3]) { date.setMonth(d[3] - 1); }
  if (d[5]) { date.setDate(d[1]); }
  if (d[7]) {
    date.setHours(parseInt(d[7], 10));    
  }
  if (d[8]) { date.setMinutes(d[8]); }
  if (d[10]) { date.setSeconds(d[10]); }
  return date;
}
