/**
 * Pads a given hour with a leading zero if it's less than 10
 * @param {number|string} hour - The hour to be padded
 * @returns {string} A string representation of the hour, padded with a leading zero if necessary
 */
Date.padded2 = function(hour) { padded2 = hour.toString(); if ((parseInt(hour) < 10) || (parseInt(hour) == null)) padded2="0" + padded2; return padded2; }
Date.prototype.getAMPMHour = function() { hour=Date.padded2(this.getHours()); return (hour == null) ? 00 : (hour > 24 ? hour - 24 : hour ) }
/**
 * Gets the AM/PM indicator for the current time
 * @returns {string} Returns an empty string for AM or "PM" for PM
 */
Date.prototype.getAMPM = function() { return (this.getHours() < 12) ? "" : ""; }

/**
 * Converts a Date object to a formatted string representation.
 * @param {boolean} include_time - Whether to include the time in the formatted string.
 * @returns {string} A formatted string representation of the date, optionally including time.
 */
Date.prototype.toFormattedString = function(include_time){
  str = this.getDate() + "." + (this.getMonth() + 1) + "." + this.getFullYear();
  if (include_time) { hour=this.getHours(); str += " " + this.getAMPMHour() + ":" + this.getPaddedMinutes() }
  return str;
}
Date.parseFormattedString = function (string) {
  var regexp = '([0-9]{1,2})\.(([0-9]{1,2})\.(([0-9]{4})( ([0-9]{1,2}):([0-9]{2})? *)?)?)?';
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
