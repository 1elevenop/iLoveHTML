document.addEventListener('DOMContentLoaded', function () {
  var el = document.getElementById('status');
  el.textContent = 'JavaScript is running (' + location.origin + ')';
  el.className = 'ok';
  console.log('html2apk demo loaded');
});
