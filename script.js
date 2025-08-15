function postNUI(event, payload) {
  fetch(`https://${GetParentResourceName()}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(payload || {})
  });
}

window.addEventListener('message', function (event) {
  if (event.data.action === "openUI") {
    document.body.style.display = "block";
    const enabled = !!event.data.enabled;
    const dist = Math.floor(event.data.distance || 50);
    document.getElementById("toggle").checked = enabled;
    document.getElementById("toggleLabel").innerText = enabled ? "Detection ON" : "Detection OFF";
    document.getElementById("distance").value = dist;
    document.getElementById("distanceValue").innerText = dist;
  }
});

document.getElementById("toggle").addEventListener("change", function() {
  const state = this.checked;
  document.getElementById("toggleLabel").innerText = state ? "Detection ON" : "Detection OFF";
  postNUI("toggleDetection", { state });
});

document.getElementById("distance").addEventListener("input", function () {
  const val = parseInt(this.value, 10) || 50;
  document.getElementById("distanceValue").innerText = val;
  postNUI("setDistance", { distance: val });
});

document.getElementById("closeBtn").addEventListener("click", function() {
  document.body.style.display = "none";
  postNUI("escape", {});
});

document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape') {
    document.body.style.display = "none";
    postNUI("escape", {});
  }
});
