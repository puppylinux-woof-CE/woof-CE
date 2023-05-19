sessionStorage.setItem("link_hash_id", window.location.toString().split('#')[1]);

function changeBackground() {
	let id = sessionStorage.getItem("link_hash_id");

	if(id != "") {
		if(!isNaN(id)) {
			document.getElementById(id).style.backgroundColor = "#fff";
//			console.log("Removed " + id);
		}
	}

	sessionStorage.setItem("link_hash_id", window.location.toString().split('#')[1]);
	id = sessionStorage.getItem("link_hash_id");

	if(id != "") {
		if(!isNaN(id)) {
			document.getElementById(id).style.backgroundColor = "#56a8ff55";
//			console.log("Added " + id);
		}
	}
}

window.addEventListener("hashchange", changeBackground);
window.addEventListener("load", changeBackground);
