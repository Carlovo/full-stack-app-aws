"use strict";

var mainTable = document.getElementById("mainTable");
var optionsTable = document.getElementById("optionsTable");

var tableEntries = [];
var apiUrl = "${api_url}";

var minimalApp = new function () {

    this.appendOptionRow = function (innerHTML, checked, onclick) {

        var tr = optionsTable.insertRow(-1);

        var optionLabelCell = tr.insertCell(-1);
        optionLabelCell.innerHTML = innerHTML;

        var checkCell = tr.insertCell(-1);

        var optionCheckbox = document.createElement("input");
        optionCheckbox.setAttribute("type", "checkbox");
        optionCheckbox.setAttribute("id", "Options-" + innerHTML);
        optionCheckbox.disabled = true;
        optionCheckbox.checked = checked;
        optionCheckbox.setAttribute("onclick", onclick);
        checkCell.appendChild(optionCheckbox);
    };

    this.buildOptionsTable = function () {

        optionsTable.innerHTML = "";
        optionsTable.style.margin = "24px 0px";

        minimalApp.appendOptionRow("Timestamp", false, "minimalApp.buildMainTable()");
        minimalApp.appendOptionRow("Checkboxes", false, "minimalApp.buildMainTable()");
        minimalApp.appendOptionRow("CRUD", true, "minimalApp.buildMainTable()");
        minimalApp.appendOptionRow("Online", true, "minimalApp.loadBuildMainTable()");
    };

    this.appendStandardButton = function (parent, value, entryNumber, onclick) {

        var standardButton = document.createElement("input");
        standardButton.setAttribute("type", "button");
        standardButton.setAttribute("value", value);
        standardButton.setAttribute("id", value + "-" + entryNumber);
        standardButton.setAttribute("onclick", onclick);
        parent.appendChild(standardButton);
    };

    this.appendItemRow = function (entryNumber) {

        var tr = mainTable.insertRow(-1);
        tr.setAttribute("id", "tr-" + entryNumber);

        var idCell = tr.insertCell(-1);
        idCell.innerHTML = tableEntries[entryNumber]["id"];
        idCell.setAttribute("id", "Id-" + entryNumber);
        idCell.setAttribute("style", "display:none;");

        var cbOptionsTimestamp = document.getElementById("Options-Timestamp");

        if (cbOptionsTimestamp.checked) {

            var timestampCell = tr.insertCell(-1);
            timestampCell.style.fontSize = "x-small";
            timestampCell.style.fontStyle = "italic";
            timestampCell.innerHTML = tableEntries[entryNumber]["timestamp"];
            timestampCell.setAttribute("id", "Timestamp-" + entryNumber);
        };

        var cbOptionsCheck = document.getElementById("Options-Checkboxes");

        if (cbOptionsCheck.checked) {

            var checkCell = tr.insertCell(-1);

            var cbCheck = document.createElement("input");
            checkCell.setAttribute("class", "check");
            cbCheck.setAttribute("type", "checkbox");
            cbCheck.checked = tableEntries[entryNumber]["check"];
            cbCheck.setAttribute("id", "Check-" + entryNumber);
            cbCheck.setAttribute("onclick", "minimalApp.updateBackEnd(this)");
            checkCell.appendChild(cbCheck);
        };

        var nameCell = tr.insertCell(-1);
        nameCell.innerHTML = tableEntries[entryNumber]["name"];
        nameCell.setAttribute("id", "Name-" + entryNumber);

        var cbOptionsCrud = document.getElementById("Options-CRUD");

        if (cbOptionsCrud.checked) {

            var updateCell = tr.insertCell(-1);

            minimalApp.appendStandardButton(
                updateCell, "Update", entryNumber, "minimalApp.editItem(this)"
            );
            minimalApp.appendStandardButton(
                updateCell, "Cancel", entryNumber, "minimalApp.cancelEditName(this)"
            );
            minimalApp.appendStandardButton(
                updateCell, "Save", entryNumber, "minimalApp.updateBackEnd(this)"
            );

            var deleteCell = tr.insertCell(-1);

            minimalApp.appendStandardButton(
                deleteCell, "Delete", entryNumber, "minimalApp.updateBackEnd(this)"
            );

            minimalApp.toggleEditItemButtons(entryNumber, false);
        };
    };

    this.appendCreateRow = function (entryNumber) {

        var tr = mainTable.insertRow(-1);

        // these are just placeholders
        var idCell = tr.insertCell(-1);
        idCell.innerHTML = "-";
        idCell.setAttribute("id", "Id-" + entryNumber);
        idCell.setAttribute("style", "display:none;");

        var cbOptionsTimestamp = document.getElementById("Options-Timestamp");

        if (cbOptionsTimestamp.checked) {

            var timestampCell = tr.insertCell(-1);
            timestampCell.setAttribute("id", "Timestamp-" + entryNumber);
        };

        var cbOptionsCheck = document.getElementById("Options-Checkboxes");

        if (cbOptionsCheck.checked) {

            var checkCell = tr.insertCell(-1);
            checkCell.setAttribute("class", "check");
            checkCell.setAttribute("id", "Check-" + entryNumber);
        };

        // these are actual content
        var newCell = tr.insertCell(-1);
        newCell.setAttribute("id", "Name-" + entryNumber);

        var tBox = document.createElement("input");
        tBox.setAttribute("type", "text");
        tBox.setAttribute("value", "");
        tBox.setAttribute("style", "touch-action: none");

        newCell.appendChild(tBox);

        var createCell = tr.insertCell(-1);

        minimalApp.appendStandardButton(
            createCell, "Create", entryNumber, "minimalApp.updateBackEnd(this)"
        );

        // another placeholder
        tr.insertCell(-1);
    };

    this.buildMainTable = function () {

        mainTable.innerHTML = "";

        var cbOptionsTimestamp = document.getElementById("Options-Timestamp");
        cbOptionsTimestamp.disabled = false;
        var cbOptionsCheck = document.getElementById("Options-Checkboxes");
        cbOptionsCheck.disabled = false;
        var cbOptionsCrud = document.getElementById("Options-CRUD");
        cbOptionsCrud.disabled = false;
        var cbOptionsOnline = document.getElementById("Options-Online");
        cbOptionsOnline.disabled = false;

        for (var entryNumber = 0; entryNumber < tableEntries.length; entryNumber++) {

            minimalApp.appendItemRow(entryNumber);
        };

        if (cbOptionsCrud.checked) {
            minimalApp.appendCreateRow(entryNumber);
        };

        minimalApp.scaleContent();
    };

    this.createCustomTimestamp = function () {

        var timestamp = new Date();
        var timestampString = timestamp.toISOString();
        var customTimestamp = timestampString.substring(0, 19);
        return customTimestamp.replace("T", " ");
    }

    this.updateBackEnd = function (inputElement) {

        var activeRow = inputElement.id.split("-")[1];

        var cbOptionsOnline = document.getElementById("Options-Online");

        if (cbOptionsOnline.checked) {

            var idCell = document.getElementById("Id-" + activeRow);

            var payloadDict = { "id": idCell.innerHTML };

            if (inputElement.value == "Delete") {

                payloadDict["operation"] = "Delete";
            } else {

                nameCell = document.getElementById("Name-" + activeRow);

                if (inputElement.type == "checkbox") {

                    payloadDict["operation"] = "Save";
                    payloadDict["name"] = nameCell.innerHTML;
                    payloadDict["check"] = inputElement.checked;
                } else {

                    if (nameCell.childNodes[0].value == "") {

                        alert("input field may not be empty");
                        return;
                    } else {

                        payloadDict["operation"] = inputElement.value;
                        payloadDict["name"] = nameCell.childNodes[0].value;

                        if (inputElement.value == "Create") {

                            var customTimestamp = minimalApp.createCustomTimestamp();
                            payloadDict["timestamp"] = customTimestamp;
                        } else {

                            payloadDict["check"] = tableEntries[activeRow]["check"];
                        };
                    };
                };
            };

            var payloadText = JSON.stringify(payloadDict);

            minimalApp.xhttpBackEnd(payloadText);
        } else {

            if (inputElement.type == "checkbox") {

                tableEntries[activeRow]["check"] = inputElement.checked;
            } else {

                if (inputElement.value == "Delete") {

                    tableEntries.splice(activeRow, 1);
                };

                if (inputElement.value == "Create" || inputElement.value == "Save") {

                    var nameCell = document.getElementById("Name-" + activeRow);

                    if (nameCell.childNodes[0].value == "") {

                        alert("input field may not be empty");
                    } else {

                        if (inputElement.value == "Create") {

                            var customTimestamp = minimalApp.createCustomTimestamp();

                            tableEntries.push({
                                "id": activeRow,
                                "name": nameCell.childNodes[0].value,
                                "check": false,
                                "timestamp": customTimestamp
                            });
                        } else {

                            tableEntries[activeRow]["name"] = nameCell.childNodes[0].value;
                        };
                    };
                };
            };

            minimalApp.buildMainTable();
        };
    };

    this.xhttpBackEnd = function (payload) {

        var xhttp = new XMLHttpRequest();

        xhttp.onreadystatechange = function () {

            if (this.readyState == 4 && this.status == 200) {

                tableEntries = JSON.parse(this.responseText);
                tableEntries.sort((a, b) => a.timestamp.localeCompare(b.timestamp));

                minimalApp.buildMainTable();
            };
        };

        xhttp.open("POST", apiUrl, true);

        xhttp.send(payload);

        var inputElements = document.getElementsByTagName("input");

        Object.keys(inputElements).forEach(function (key) {
            inputElements[key].disabled = true;
        });
    };

    this.editItem = function (oButton) {

        var activeRow = oButton.id.split("-")[1];
        var nameCell = document.getElementById("Name-" + activeRow);

        var inputBox = document.createElement("input");
        inputBox.setAttribute("type", "text");
        inputBox.setAttribute("value", nameCell.innerText);
        inputBox.setAttribute("style", "touch-action: none");
        nameCell.innerText = "";
        nameCell.appendChild(inputBox);

        minimalApp.toggleEditItemButtons(activeRow, true);
    };

    this.cancelEditName = function (oButton) {

        var activeRow = oButton.id.split("-")[1];

        var nameCell = document.getElementById("Name-" + activeRow);
        nameCell.innerHTML = tableEntries[activeRow]["name"];

        minimalApp.toggleEditItemButtons(activeRow, false);
    };

    this.toggleEditItemButtons = function (activeRow, editMode) {

        if (editMode) {

            var nameEditDisplay = "block";
            var optionsDisplay = "none";
        } else {

            var nameEditDisplay = "none";
            var optionsDisplay = "block";
        };

        var cbOptionsCheck = document.getElementById("Options-Checkboxes");

        if (cbOptionsCheck.checked) {

            var cbCheck = document.getElementById("Check-" + activeRow);
            cbCheck.setAttribute("style", "display:" + optionsDisplay);
        };

        var cbOptionsCrud = document.getElementById("Options-CRUD");

        if (cbOptionsCrud.checked) {

            var btUpdate = document.getElementById("Update-" + activeRow);
            btUpdate.setAttribute("style", "display:" + optionsDisplay);
            var btDelete = document.getElementById("Delete-" + activeRow);
            btDelete.setAttribute("style", "display:" + optionsDisplay);

            var btCancel = document.getElementById("Cancel-" + activeRow);
            btCancel.setAttribute("style", "display:" + nameEditDisplay);
            var btSave = document.getElementById("Save-" + activeRow);
            btSave.setAttribute("style", "display:" + nameEditDisplay);
        };
    };

    this.scaleContent = function () {

        var containerDiv = document.getElementById("container");
        var mainTable = document.getElementById("mainTable");

        containerDiv.style["transform"] = "initial";
        containerDiv.style["transformOrigin"] = "initial";

        // scale contents to smallest window dimension and center
        var scale = Math.min(
            window.innerHeight / mainTable.offsetWidth,
            window.innerWidth / mainTable.offsetWidth
        );

        containerDiv.style.width = mainTable.offsetWidth + "px";
        containerDiv.style.margin = "auto";
        containerDiv.style["transform"] = "scale(" + scale + ")";
        containerDiv.style["transformOrigin"] = "center top";
    };

    this.loadBuildMainTable = function () {

        var xhttp = new XMLHttpRequest();

        xhttp.onreadystatechange = function () {

            if (this.readyState == 4 && this.status == 200) {

                tableEntries = JSON.parse(this.responseText);
                tableEntries.sort((a, b) => a.timestamp.localeCompare(b.timestamp));

                minimalApp.buildMainTable();
            };
        };

        xhttp.open("GET", apiUrl, true);
        xhttp.send();
    };
};

minimalApp.buildOptionsTable();
minimalApp.loadBuildMainTable();
