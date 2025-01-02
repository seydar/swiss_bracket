function add_team() {
  let label = document.createElement("label");
  label.appendChild(document.createTextNode("Team:"));

  let name = document.getElementById('team_name').value;

  let input = document.createElement("input");
  input.setAttribute('name', 'teams[]');
  input.setAttribute('value', name);

  let ul = document.getElementById('team_list');

  let li = document.createElement("li");

  li.appendChild(label);
  li.appendChild(input);

  ul.appendChild(li);

  let inp = document.getElementById("team_name");
  inp.value = "";
}
