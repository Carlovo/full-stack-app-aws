var apiUrl = "${api_url}"

var minimalApp = new function () {

    this.buildTable = function (jsonText) {

        var tableEntries = JSON.parse(jsonText)
        var table = document.createElement("table");
        table.setAttribute("id", "minimalTable");

        for (var entryNumber = 0; entryNumber < tableEntries.length; entryNumber++) {

            tr = table.insertRow(-1);

            var idCell = tr.insertCell(-1);
            idCell.innerHTML = tableEntries[entryNumber]["id"];
            idCell.setAttribute("id", "Id-" + entryNumber);
            idCell.setAttribute("style", "display:none;");

            var nameCell = tr.insertCell(-1);
            nameCell.innerHTML = tableEntries[entryNumber]["name"];
            nameCell.setAttribute("id", "Name-" + entryNumber);

            var updateCell = tr.insertCell(-1);

            var btUpdate = document.createElement("input");
            btUpdate.setAttribute("type", "button");
            btUpdate.setAttribute("value", "Update");
            btUpdate.setAttribute("id", "Update-" + entryNumber);
            btUpdate.setAttribute("onclick", "minimalApp.editItem(this)");
            updateCell.appendChild(btUpdate);

            var btCancel = document.createElement("input");
            btCancel.setAttribute("type", "button");
            btCancel.setAttribute("value", "Cancel");
            btCancel.setAttribute("id", "Cancel-" + entryNumber);
            btCancel.setAttribute("style", "display:none;");
            btCancel.setAttribute("onclick", "minimalApp.loadFrontEnd()");
            updateCell.appendChild(btCancel);

            var btSave = document.createElement("input");
            btSave.setAttribute("type", "button");
            btSave.setAttribute("value", "Save");
            btSave.setAttribute("id", "Save-" + entryNumber);
            btSave.setAttribute("style", "display:none;");
            btSave.setAttribute("onclick", "minimalApp.updateBackEnd(this)");
            updateCell.appendChild(btSave);

            var deleteCell = tr.insertCell(-1);
            var btDelete = document.createElement("input");
            btDelete.setAttribute("type", "button");
            btDelete.setAttribute("value", "Delete");
            btDelete.setAttribute("id", "Delete-" + entryNumber);
            btDelete.setAttribute("onclick", "minimalApp.updateBackEnd(this)");
            deleteCell.appendChild(btDelete);
        }

        tr = table.insertRow(-1);

        // this is just a placeholder
        var idCell = tr.insertCell(-1);
        idCell.innerHTML = "-";
        idCell.setAttribute("id", "Id-" + entryNumber);
        idCell.setAttribute("style", "display:none;");

        var newCell = tr.insertCell(-1);
        newCell.setAttribute("id", "Name-" + entryNumber);

        var tBox = document.createElement("input");
        tBox.setAttribute("type", "text");
        tBox.setAttribute("value", "");
        tBox.setAttribute("style", "touch-action: none")

        newCell.appendChild(tBox);

        var createCell = tr.insertCell(-1);
        var btNew = document.createElement("input");
        btNew.setAttribute("type", "button");
        btNew.setAttribute("value", "Create");
        btNew.setAttribute("id", "Create-" + entryNumber);
        btNew.setAttribute("onclick", "minimalApp.updateBackEnd(this)");
        createCell.appendChild(btNew);

        var div = document.getElementById("minimal-table");
        div.innerHTML = "";
        div.appendChild(table);

        // scale contents to smallest window dimension and center
        var scale = Math.min(
            window.innerHeight / table.clientWidth,
            window.innerWidth / table.clientWidth
        );

        table.style["transform"] = "scale(" + scale + ")";
        table.style["transformOrigin"] = "0% 0%";

        div.style.width = scale * table.clientWidth + "px";
        div.style.margin = "auto";
    }

    this.updateBackEnd = function (oButton) {

        var activeRow = oButton.id.split("-")[1];
        var idCell = document.getElementById("Id-" + activeRow);
        var nameCell = document.getElementById("Name-" + activeRow);

        if (nameCell.childNodes[0].value != "") {

            var xhttp = new XMLHttpRequest();

            xhttp.onreadystatechange = function () {

                if (this.readyState == 4 && this.status == 200) {

                    minimalApp.buildTable(this.responseText)
                }
            }

            xhttp.open("POST", apiUrl, true);

            payload = JSON.stringify({
                "operation": oButton.value,
                "id": idCell.innerHTML,
                "name": nameCell.childNodes[0].value
            })

            xhttp.send(payload);

            var inputElements = document.getElementsByTagName("input");

            Object.keys(inputElements).forEach(function (key) {
                inputElements[key].disabled = true;
            });
        }
        else {

            alert("input field may not be empty");
        }
    }

    this.editItem = function (oButton) {

        var activeRow = oButton.id.split("-")[1];
        var nameCell = document.getElementById("Name-" + activeRow);

        var inputBox = document.createElement("input");
        inputBox.setAttribute("type", "text");
        inputBox.setAttribute("value", nameCell.innerText);
        inputBox.setAttribute("style", "touch-action: none")
        nameCell.innerText = "";
        nameCell.appendChild(inputBox);

        var btCancel = document.getElementById("Cancel-" + activeRow);
        btCancel.setAttribute("style", "display:block");

        var btSave = document.getElementById("Save-" + activeRow);
        btSave.setAttribute("style", "display:block");

        var btDelete = document.getElementById("Delete-" + activeRow);
        btDelete.setAttribute("style", "display:none");

        oButton.setAttribute("style", "display:none;");
    }

    this.loadFrontEnd = function () {

        var xhttp = new XMLHttpRequest();

        xhttp.onreadystatechange = function () {

            if (this.readyState == 4 && this.status == 200) {

                minimalApp.buildTable(this.responseText)
            }
        }

        xhttp.open("GET", apiUrl, true);
        xhttp.send();
    }
}

minimalApp.loadFrontEnd()
