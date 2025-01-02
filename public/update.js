function add_player(team) {
  let player_label = document.createElement("label");
  player_label.appendChild(document.createTextNode("Player:"));

  let name = document.getElementById(team + '_player_name').value;

  let player_input = document.createElement("input");
  player_input.setAttribute('name', 'players[' + team + '][names][]');
  player_input.setAttribute('value', name);

  let phone_label = document.createElement("label");
  phone_label.appendChild(document.createTextNode("Phone:"));

  let phone = document.getElementById(team + '_player_phone').value;

  let phone_input = document.createElement("input");
  phone_input.setAttribute('name', 'players[' + team + '][phones][]');
  phone_input.setAttribute('value', phone);

  let ul = document.getElementById(team + '_players_list');

  let li = document.createElement("li");

  li.appendChild(player_label);
  li.appendChild(player_input);

  li.appendChild(phone_label);
  li.appendChild(phone_input);

  ul.appendChild(li);

  let inp = document.getElementById(team + "_player_name");
  inp.value = "";

  inp = document.getElementById(team + "_player_phone");
  inp.value = "";
}

function remove_el(el) {
  el.remove();
}

