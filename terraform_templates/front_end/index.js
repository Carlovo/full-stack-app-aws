"use strict";

const containerDiv = document.getElementById("container");
const mainTable = document.getElementById("mainTable");
const mainTableDefaultHTML = mainTable.innerHTML;

const sortOptions = [
    "Priority",
    "Timestamp",
    "Checkboxes",
    "Name",
    "Modified"
];

var tableEntries = [];
var refreshDict = {};
// Templated by Terraform
const apiUrl = "${api_url}";

const queryParams = new URLSearchParams(window.location.search);
const queryTable = queryParams.get("table");

var minimalApp = new function () {

    this.appendStandardButton = function (parent, value, entryNumber, onclick) {

        var standardButton = document.createElement("input");
        standardButton.setAttribute("type", "button");
        standardButton.setAttribute("value", value);
        standardButton.setAttribute("id", value + "-" + entryNumber);
        standardButton.setAttribute("onclick", onclick);
        parent.appendChild(standardButton);
    };

    this.appendItemRow = function (tableEntry, entryNumber) {

        var tr = mainTable.insertRow(-1);
        tr.setAttribute("id", "tr-" + entryNumber);

        var idCell = tr.insertCell(-1);
        idCell.innerHTML = tableEntry["id"];
        idCell.setAttribute("id", "Id-" + entryNumber);
        idCell.setAttribute("style", "display:none;");

        var cbOptionsTimestamp = document.getElementById("Options-Timestamp");

        if (cbOptionsTimestamp.checked) {

            var jsDate = new Date(tableEntry["timestamp"]);

            var timestampCell = tr.insertCell(-1);
            timestampCell.style.fontSize = "x-small";
            timestampCell.style.fontStyle = "italic";
            // short, most significant numbers come first and most visually different separators between date and time
            timestampCell.innerHTML = jsDate.toLocaleString("sv-SE");
            timestampCell.setAttribute("id", "Timestamp-" + entryNumber);
        };

        var cbOptionsModified = document.getElementById("Options-Modified");

        if (cbOptionsModified.checked) {

            var jsDate = new Date(tableEntry["modified"]);

            var modifiedCell = tr.insertCell(-1);
            modifiedCell.style.fontSize = "x-small";
            modifiedCell.style.fontStyle = "italic";
            // short, most significant numbers come first and most visually different separators between date and time
            modifiedCell.innerHTML = jsDate.toLocaleString("sv-SE");
            modifiedCell.setAttribute("id", "Modified-" + entryNumber);
        };

        var cbOptionsCheck = document.getElementById("Options-Checkboxes");

        if (cbOptionsCheck.checked) {

            var checkCell = tr.insertCell(-1);

            var cbCheck = document.createElement("input");
            checkCell.setAttribute("class", "check");
            cbCheck.setAttribute("type", "checkbox");
            cbCheck.checked = tableEntry["check"];
            cbCheck.setAttribute("id", "Check-" + entryNumber);
            cbCheck.setAttribute("onclick", "minimalApp.updateItemCheck(" + entryNumber + ")");
            checkCell.appendChild(cbCheck);
        };

        var cbOptionsPriority = document.getElementById("Options-Priority");

        if (cbOptionsPriority.checked) {

            var priorityCell = tr.insertCell(-1);
            priorityCell.innerHTML = tableEntry["priority"];
            priorityCell.setAttribute("id", "Priority-" + entryNumber);
        };

        var nameCell = tr.insertCell(-1);
        nameCell.innerHTML = tableEntry["name"];
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
                updateCell, "Save", entryNumber, "minimalApp.updateItemNameAndPriority(" + entryNumber + ")"
            );

            var deleteCell = tr.insertCell(-1);

            minimalApp.appendStandardButton(
                deleteCell, "Delete", entryNumber, "minimalApp.deleteItem(" + entryNumber + ")"
            );

            minimalApp.toggleEditItemButtons(entryNumber, false);
        };
    };

    this.appendCreateRow = function () {

        var tr = mainTable.insertRow(-1);

        // these are just placeholders
        var idCell = tr.insertCell(-1);
        idCell.innerHTML = tableEntries.length;
        idCell.setAttribute("id", "Id-" + tableEntries.length);
        idCell.setAttribute("style", "display:none;");

        var cbOptionsTimestamp = document.getElementById("Options-Timestamp");

        if (cbOptionsTimestamp.checked) {

            var timestampCell = tr.insertCell(-1);
            timestampCell.setAttribute("id", "Timestamp-" + tableEntries.length);
        };

        var cbOptionsModified = document.getElementById("Options-Modified");

        if (cbOptionsModified.checked) {

            var modifiedCell = tr.insertCell(-1);
            modifiedCell.setAttribute("id", "Modified-" + tableEntries.length);
        };

        var cbOptionsCheck = document.getElementById("Options-Checkboxes");

        if (cbOptionsCheck.checked) {

            var checkCell = tr.insertCell(-1);
            checkCell.setAttribute("class", "check");
            checkCell.setAttribute("id", "Check-" + tableEntries.length);
        };

        // these are actual content
        var cbOptionsPriority = document.getElementById("Options-Priority");

        if (cbOptionsPriority.checked) {

            var priorityCell = tr.insertCell(-1);
            priorityCell.setAttribute("id", "Priority-" + tableEntries.length);

            var priorityNumberBox = document.createElement("input");
            priorityNumberBox.setAttribute("type", "number");
            priorityNumberBox.setAttribute("value", 0);
            priorityNumberBox.setAttribute("style", "width: 40px; touch-action: none");

            priorityCell.appendChild(priorityNumberBox);
        };

        var nameCell = tr.insertCell(-1);
        nameCell.setAttribute("id", "Name-" + tableEntries.length);

        var nameTextBox = document.createElement("input");
        nameTextBox.setAttribute("type", "text");
        nameTextBox.setAttribute("value", "");
        nameTextBox.setAttribute("style", "touch-action: none");

        nameCell.appendChild(nameTextBox);

        var createCell = tr.insertCell(-1);

        minimalApp.appendStandardButton(
            createCell, "Create", tableEntries.length, "minimalApp.createItem()"
        );

        // another placeholder
        tr.insertCell(-1);
    };

    this.toggleDisabledInput = function (disabled) {

        var inputElements = document.getElementsByTagName("input");

        Object.keys(inputElements).forEach(function (key) {
            inputElements[key].disabled = disabled;
        });
    };

    this.buildMainTable = function () {

        mainTable.innerHTML = "";

        var sortDirections = [];

        sortOptions.forEach(function (sortOption) {

            var checkDesc = document.getElementById(sortOption + "-sort-desc");

            if (checkDesc.checked) {

                var sortDirection = -1;
            } else {

                var sortDirection = 1;
            };

            sortDirections.push(sortDirection);
        });

        var sortFunctions = [
            (a, b) => sortDirections[0] * (a.priority - b.priority),
            (a, b) => sortDirections[1] * (a.timestamp - b.timestamp),
            (a, b) => sortDirections[2] * (a.check.toString().localeCompare(b.check.toString())),
            (a, b) => sortDirections[3] * (a.name.localeCompare(b.name)),
            (a, b) => sortDirections[4] * (a.modified - b.modified)
        ];

        var sortApply = [];

        // array.forEach handles breaks and returns too awkwardly to use below

        for (var entryNumber = 0; entryNumber < sortOptions.length; entryNumber++) {

            for (var entryNumber2 = 0; entryNumber2 < sortOptions.length - 1; entryNumber2++) {

                var radioButton = document.getElementById(sortOptions[entryNumber2] + "-sort-" + entryNumber);

                if (radioButton.checked) {

                    break;
                };
            };

            sortApply.push(sortFunctions[entryNumber2]);
        };

        tableEntries.sort(function (a, b) {

            for (var entryNumber = 0; entryNumber < sortApply.length; entryNumber++) {

                var sorted = sortApply[entryNumber](a, b);

                if (sorted != 0) {

                    return sorted;
                };
            };

            return 0;
        });

        var cbOptionsCrud = document.getElementById("Options-CRUD");

        if (cbOptionsCrud.checked) {

            minimalApp.appendCreateRow();
        };

        tableEntries.forEach((tableEntry, entryNumber) => minimalApp.appendItemRow(tableEntry, entryNumber));

        minimalApp.toggleDisabledInput(false);

        minimalApp.scaleContent();
    };

    this.validateAlphanumericInput = function (entryNumber, currentPriority) {

        var valid = true;

        var nameCell = document.getElementById("Name-" + entryNumber);

        if (nameCell.childNodes[0].value == "") {

            alert("name field may not be empty");
            valid = false;
        };

        var cbOptionsPriority = document.getElementById("Options-Priority");

        if (cbOptionsPriority.checked) {

            var priorityCell = document.getElementById("Priority-" + entryNumber);

            if (priorityCell.childNodes[0].value == "") {

                alert("priority field may not be empty");
                valid = false;
            };

            currentPriority = Number(priorityCell.childNodes[0].value);
        };

        return [valid, nameCell.childNodes[0].value, currentPriority];
    };

    this.backOffGet = async function () {

        var backOff = 5;

        // Give the operations a head start before querying the table
        while (Object.values(refreshDict).includes(false)) {

            backOff = 2 * backOff;
            await new Promise(r => setTimeout(r, backOff));
        };

        minimalApp.xhttpGetTableEntries();

        refreshDict = {};
    };

    this.batchRequest = function (operation, items) {

        // DynamoDB batch operation size limit is 25 items
        if (items.length > 25) {

            var it, it2, tempArray, chunk = 25;

            for (it = 0, it2 = items.length; it < it2; it += chunk) {

                refreshDict[String(it)] = false;

                tempArray = items.slice(it, it + chunk);
                minimalApp.xhttpQueryBackEnd("POST", "", { "operation": operation, "items": tempArray }, String(it));
            };

            minimalApp.backOffGet();
        } else {

            minimalApp.xhttpQueryBackEnd("POST", "", { "operation": operation, "items": items });
        };
    };

    this.createItem = function () {

        var itemDict = {};
        var valid;

        [
            valid,
            itemDict["name"],
            itemDict["priority"]
        ] = minimalApp.validateAlphanumericInput(tableEntries.length, 0);

        if (valid) {

            itemDict["check"] = false;

            var cbOptionsOnline = document.getElementById("Options-Online");

            if (cbOptionsOnline.checked) {

                minimalApp.batchRequest("put", [itemDict]);
            } else {

                // this is not foolproof, but it's not used downstream in the current setup
                itemDict["id"] = tableEntries.length;

                console.log(itemDict);

                tableEntries.push(itemDict);

                minimalApp.buildMainTable();
            };
        };
    };

    this.updateItemNameAndPriority = function (entryNumber) {

        var itemDict = tableEntries[entryNumber];

        var valid;

        [
            valid,
            itemDict["name"],
            itemDict["priority"]
        ] = minimalApp.validateAlphanumericInput(entryNumber, itemDict["priority"]);

        if (valid) {

            var cbOptionsOnline = document.getElementById("Options-Online");

            if (cbOptionsOnline.checked) {

                minimalApp.xhttpQueryBackEnd("PATCH", itemDict["id"], itemDict);
            } else {

                console.log(itemDict);

                tableEntries[entryNumber] = itemDict

                minimalApp.buildMainTable();
            };
        };
    };

    this.updateItemCheck = function (entryNumber) {

        var inputElement = document.getElementById("Check-" + entryNumber);
        var itemDict = tableEntries[entryNumber];

        itemDict["check"] = inputElement.checked;

        var cbOptionsOnline = document.getElementById("Options-Online");

        if (cbOptionsOnline.checked) {

            minimalApp.xhttpQueryBackEnd("PATCH", itemDict["id"], itemDict);
        } else {

            tableEntries[entryNumber]["check"] = inputElement.checked;

            console.log(itemDict);
        };
    };

    this.deleteItem = function (entryNumber) {

        var cbOptionsOnline = document.getElementById("Options-Online");

        if (cbOptionsOnline.checked) {

            minimalApp.xhttpQueryBackEnd("DELETE", tableEntries[entryNumber]["id"]);
        } else {

            var itemDict = tableEntries[entryNumber];

            tableEntries.splice(entryNumber, 1);

            console.log(itemDict);

            minimalApp.buildMainTable();
        };
    };

    this.inputBulkMultiline = function () {

        var cbOptionsOnline = document.getElementById("Options-Online");

        if (cbOptionsOnline.checked) {

            var taName = document.getElementById("Name-Bulk-Multiline");
            var nbPriority = document.getElementById("Priority-Bulk-Multiline");

            if (taName.value == "" || nbPriority.value == "") {

                alert("bulk input fields may not be empty");
            } else {

                var cbCheck = document.getElementById("Check-Bulk-Multiline");
                var names = taName.value.split("\n");
                var items = [];
                var priority = Number(nbPriority.value);

                names.forEach(function (name) {
                    items.push({
                        "name": name,
                        "priority": priority,
                        "check": cbCheck.checked
                    });
                });

                minimalApp.batchRequest("put", items);
            };
        } else {

            alert("Bulk operations can only be used in online mode");
        };
    };

    this.inputBulkDeleteAllOnCheck = function (deleteChecked) {

        var cbOptionsOnline = document.getElementById("Options-Online");

        if (cbOptionsOnline.checked) {

            if (deleteChecked) {

                var checkedItems = tableEntries.filter(item => item["check"]);
            } else {

                var checkedItems = tableEntries.filter(item => !(item["check"]));
            };

            var checkedItemKeys = checkedItems.map(item => item["id"]);

            minimalApp.batchRequest("delete", checkedItemKeys);
        } else {

            alert("Bulk operations can only be used in online mode");
        };
    };

    this.inputBulkInvertCheck = function (select = 0) {

        var cbOptionsOnline = document.getElementById("Options-Online");

        if (cbOptionsOnline.checked) {

            if (select == 1) {

                var tableCopy = tableEntries.filter(item => item["check"]);
            } else if (select == -1) {

                var tableCopy = tableEntries.filter(item => !(item["check"]));
            } else {

                var tableCopy = tableEntries;
            };

            tableCopy.forEach(function (entry) {

                refreshDict[entry["id"]] = false;

                minimalApp.xhttpQueryBackEnd(
                    "PATCH",
                    entry["id"],
                    {
                        "name": entry["name"],
                        "priority": entry["priority"],
                        "check": !(entry["check"])
                    },
                    entry["id"]
                );
            });

            minimalApp.backOffGet();
        } else {

            alert("Bulk operations can only be used in online mode");
        };
    };

    this.alertInvalidRequest = function () {

        alert("invalid request");

        var viewDetails = document.getElementById("viewDetails");
        viewDetails.setAttribute("style", "display:none");

        var sortDetails = document.getElementById("sortDetails");
        sortDetails.setAttribute("style", "display:none");

        var bulkDetails = document.getElementById("bulkDetails");
        bulkDetails.setAttribute("style", "display:none");

        mainTable.innerHTML = mainTableDefaultHTML;

        minimalApp.scaleContent();
    };

    this.xhttpGetTableEntries = function () {

        var xhttp = new XMLHttpRequest();

        xhttp.onreadystatechange = function () {

            if (this.readyState == 4) {

                if (this.status == 200) {

                    tableEntries = JSON.parse(this.responseText);

                    minimalApp.buildMainTable();
                } else {

                    minimalApp.alertInvalidRequest();
                };
            };
        };

        xhttp.open("GET", apiUrl + queryTable);

        xhttp.send();

        minimalApp.toggleDisabledInput(true);
    };

    this.xhttpQueryBackEnd = function (method, urlAppendix = "", bodyDict = {}, refresh = "") {

        var bodyText = JSON.stringify(bodyDict);
        var xhttp = new XMLHttpRequest();

        console.log(bodyText);

        xhttp.onreadystatechange = function () {

            if (this.readyState == 4) {

                if (this.status == 200) {

                    if (refresh == "") {

                        minimalApp.xhttpGetTableEntries();
                    } else {

                        refreshDict[refresh] = true;
                    };
                } else {

                    minimalApp.alertInvalidRequest();
                };
            };
        };

        xhttp.open(method, apiUrl + queryTable + "/" + urlAppendix);
        xhttp.setRequestHeader("Content-Type", "application/json");
        xhttp.send(bodyText);

        minimalApp.toggleDisabledInput(true);
    };

    this.editItem = function (oButton) {

        var entryNumber = oButton.id.split("-")[1];

        var cbOptionsPriority = document.getElementById("Options-Priority");

        if (cbOptionsPriority.checked) {

            var priorityCell = document.getElementById("Priority-" + entryNumber);

            var priorityNumberBox = document.createElement("input");
            priorityNumberBox.setAttribute("type", "number");
            priorityNumberBox.setAttribute("value", tableEntries[entryNumber]["priority"]);
            priorityNumberBox.setAttribute("style", "width: 40px; touch-action: none");
            priorityCell.innerText = "";
            priorityCell.appendChild(priorityNumberBox);
        };

        var nameCell = document.getElementById("Name-" + entryNumber);

        var nameTextBox = document.createElement("input");
        nameTextBox.setAttribute("type", "text");
        nameTextBox.setAttribute("value", tableEntries[entryNumber]["name"]);
        nameTextBox.setAttribute("style", "touch-action: none");
        nameCell.innerText = "";
        nameCell.appendChild(nameTextBox);

        minimalApp.toggleEditItemButtons(entryNumber, true);
    };

    this.cancelEditName = function (oButton) {

        var entryNumber = oButton.id.split("-")[1];

        var cbOptionsPriority = document.getElementById("Options-Priority");

        if (cbOptionsPriority.checked) {

            var priorityCell = document.getElementById("Priority-" + entryNumber);
            priorityCell.innerHTML = tableEntries[entryNumber]["priority"];
        };

        var nameCell = document.getElementById("Name-" + entryNumber);
        nameCell.innerHTML = tableEntries[entryNumber]["name"];

        minimalApp.toggleEditItemButtons(entryNumber, false);
    };

    this.radioButton2D = function (radioButtonClicked) {

        var entryNumber = radioButtonClicked.id.split("-")[2];

        for (var entryNumber2 = 0; entryNumber2 < sortOptions.length; entryNumber2++) {

            var radioButton = document.getElementById(sortOptions[entryNumber2] + "-sort-" + entryNumber);

            if (radioButton.checked && radioButton != radioButtonClicked) {

                radioButton.checked = false;
                radioButtonClicked = radioButton;

                break;
            };
        };

        for (var entryNumber = 0; entryNumber < sortOptions.length; entryNumber++) {

            for (var entryNumber2 = 0; entryNumber2 < sortOptions.length; entryNumber2++) {

                var radioButton = document.getElementById(sortOptions[entryNumber2] + "-sort-" + entryNumber);

                if (radioButton.checked) {

                    break;
                };
            };

            if (entryNumber2 == sortOptions.length) {

                var radioButton = document.getElementById(radioButtonClicked.id.split("-")[0] + "-sort-" + entryNumber);

                radioButton.checked = true;

                break;
            };
        };
    };

    this.toggleEditItemButtons = function (entryNumber, editMode) {

        if (editMode) {

            var nameEditDisplay = "block";
            var optionsDisplay = "none";
        } else {

            var nameEditDisplay = "none";
            var optionsDisplay = "block";
        };

        var cbOptionsCheck = document.getElementById("Options-Checkboxes");

        if (cbOptionsCheck.checked) {

            var cbCheck = document.getElementById("Check-" + entryNumber);
            cbCheck.setAttribute("style", "display:" + optionsDisplay);
        };

        var cbOptionsCrud = document.getElementById("Options-CRUD");

        if (cbOptionsCrud.checked) {

            var btUpdate = document.getElementById("Update-" + entryNumber);
            btUpdate.setAttribute("style", "display:" + optionsDisplay);
            var btDelete = document.getElementById("Delete-" + entryNumber);
            btDelete.setAttribute("style", "display:" + optionsDisplay);

            var btCancel = document.getElementById("Cancel-" + entryNumber);
            btCancel.setAttribute("style", "display:" + nameEditDisplay);
            var btSave = document.getElementById("Save-" + entryNumber);
            btSave.setAttribute("style", "display:" + nameEditDisplay);
        };
    };

    this.scaleContent = function () {

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

    this.renderPage = function () {

        if (typeof queryTable === "string" && queryTable.length > 0) {

            minimalApp.xhttpGetTableEntries();

            mainTable.innerHTML = "";
            var tr = mainTable.insertRow(-1);
            var td = tr.insertCell(-1);
            td.innerHTML = "loading...";

            var viewDetails = document.getElementById("viewDetails");
            viewDetails.setAttribute("style", "display:block");

            var sortDetails = document.getElementById("sortDetails");
            sortDetails.setAttribute("style", "display:block");

            var bulkDetails = document.getElementById("bulkDetails");
            bulkDetails.setAttribute("style", "display:block");
        } else {

            minimalApp.scaleContent();
        };
    };
};

minimalApp.renderPage();
