"use strict";

import {
    textractApiUrl, imageUploadBucketUrl,
    getTableEntries, createTableEntries, deleteTableEntries, deleteTableEntry, updateTableEntry
} from './api_client_library.js';

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

    this.checkSubmit = function (event, callbackFunction, parameters = null) {

        // Press enter => submit
        if (event && event.keyCode == 13) {
            callbackFunction.call(this, parameters);
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

            var cbCheck = document.createElement("input");
            checkCell.setAttribute("class", "check");
            cbCheck.setAttribute("type", "checkbox");
            cbCheck.setAttribute("id", "Check-" + tableEntries.length);
            checkCell.appendChild(cbCheck);
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
        nameTextBox.setAttribute("onKeyPress", "minimalApp.checkSubmit(event, minimalApp.createItem)");

        nameCell.appendChild(nameTextBox);

        nameTextBox.focus({ preventScroll: true });

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

        var nbPriority = document.getElementById("Priority-Bulk-Multiline");

        var entryPriorities = tableEntries.map(item => item["priority"]);

        if (entryPriorities.length > 0) {

            var maxPriority = entryPriorities.reduce(function (a, b) {
                return Math.max(a, b);
            });

            nbPriority.value = Math.floor(maxPriority + 1);
        } else {

            nbPriority.value = 0;
        };

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

        minimalApp.fetchGetTableEntries();

        refreshDict = {};
    };

    this.batchRequest = function (operation, items) {

        // DynamoDB batch operation size limit is 25 items
        if (items.length > 25) {

            var it, it2, tempArray, chunk = 25;

            for (it = 0, it2 = items.length; it < it2; it += chunk) {

                refreshDict[String(it)] = false;
                tempArray = items.slice(it, it + chunk);

                const promise = operation(queryTable, tempArray);
                minimalApp.handleTableEntriesModificationResponse(promise, String(it));
            };

            minimalApp.backOffGet();
        } else {

            const promise = operation(queryTable, items);
            minimalApp.handleTableEntriesModificationResponse(promise);
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

            var cbOptionsOnline = document.getElementById("Options-Checkboxes");

            if (cbOptionsOnline.checked) {

                var cbCheck = document.getElementById("Check-" + tableEntries.length);

                itemDict["check"] = cbCheck.checked;
            } else {

                itemDict["check"] = false;
            }

            var cbOptionsOnline = document.getElementById("Options-Online");

            if (cbOptionsOnline.checked) {

                minimalApp.batchRequest(createTableEntries, [itemDict]);
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

                const promise = updateTableEntry(queryTable, itemDict["id"], itemDict);
                minimalApp.handleTableEntriesModificationResponse(promise);
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

            const promise = updateTableEntry(queryTable, itemDict["id"], itemDict);
            minimalApp.handleTableEntriesModificationResponse(promise);
        } else {

            tableEntries[entryNumber]["check"] = inputElement.checked;

            console.log(itemDict);
        };
    };

    this.deleteItem = function (entryNumber) {

        var cbOptionsOnline = document.getElementById("Options-Online");

        if (cbOptionsOnline.checked) {

            const promise = deleteTableEntry(queryTable, tableEntries[entryNumber]["id"]);
            minimalApp.handleTableEntriesModificationResponse(promise);
        } else {

            var itemDict = tableEntries[entryNumber];

            tableEntries.splice(entryNumber, 1);

            console.log(itemDict);

            minimalApp.buildMainTable();
        };
    };

    this.parseBulkInput = function (nameList) {

        var cbInvert = document.getElementById("Invert-Bulk-Multiline");

        if (cbInvert.checked) {

            nameList = nameList.map(name => name.split(' ').reverse().join(' '));
        };

        var nbPriority = document.getElementById("Priority-Bulk-Multiline");
        var cbCheck = document.getElementById("Check-Bulk-Multiline");

        var items = [];
        var priority = Number(nbPriority.value);

        var cbIncrement = document.getElementById("Increment-Bulk-Multiline");

        nameList.forEach(function (name) {
            items.push({
                "name": name,
                "priority": priority,
                "check": cbCheck.checked
            });

            if (cbIncrement.checked) {

                priority += 0.01;
            };
        });

        minimalApp.batchRequest(createTableEntries, items);
    };

    this.inputBulkMultiline = function () {

        var cbOptionsOnline = document.getElementById("Options-Online");

        if (cbOptionsOnline.checked) {

            var nbPriority = document.getElementById("Priority-Bulk-Multiline");
            var taName = document.getElementById("Name-Bulk-Multiline");

            var nameList = taName.value.split("\n");
            var nameList = nameList.filter(name => name.trim());

            if (!nameList.length || nbPriority.value == "") {

                alert("Bulk 'Input text' and 'Priority' fields may not be empty");
            } else {

                minimalApp.parseBulkInput(nameList);
            };
        } else {

            alert("Bulk operations can only be used in online mode");
        };
    };

    this.inputBulkDeleteAllOnCheck = function (deleteChecked) {

        var cbOptionsOnline = document.getElementById("Options-Online");

        if (cbOptionsOnline.checked) {

            if (deleteChecked) {

                var prompt_message = "Delete all checked items?";
            } else {

                var prompt_message = "Delete all unchecked items?";
            };

            if (confirm(prompt_message)) {

                if (deleteChecked) {

                    var checkedItems = tableEntries.filter(item => item["check"]);
                } else {

                    var checkedItems = tableEntries.filter(item => !(item["check"]));
                };

                var checkedItemKeys = checkedItems.map(item => item["id"]);

                minimalApp.batchRequest(deleteTableEntries, checkedItemKeys);
            };
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

                const promise = updateTableEntry(
                    queryTable,
                    entry["id"],
                    {
                        "name": entry["name"],
                        "priority": entry["priority"],
                        "check": !(entry["check"])
                    }
                );
                minimalApp.handleTableEntriesModificationResponse(promise, entry["id"]);
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

        var bulkSimpleDetails = document.getElementById("bulkSimpleDetails");
        bulkSimpleDetails.setAttribute("style", "display:none");

        var bulkMultilineDetails = document.getElementById("bulkMultilineDetails");
        bulkMultilineDetails.setAttribute("style", "display:none");

        mainTable.innerHTML = mainTableDefaultHTML;

        minimalApp.scaleContent();
    };

    this.fetchGetTableEntries = function () {
        minimalApp.toggleDisabledInput(true);

        getTableEntries(queryTable)
            .then(response => {
                tableEntries = response;
                minimalApp.buildMainTable();
            })
            .catch(error => {
                minimalApp.alertInvalidRequest();
            });
    };

    this.handleTableEntriesModificationResponse = function (promise, refresh = "") {
        minimalApp.toggleDisabledInput(true);

        promise
            .then(response => {
                if (refresh == "") {
                    minimalApp.fetchGetTableEntries();
                } else {
                    refreshDict[refresh] = true;
                };
            })
            .catch(error => {
                minimalApp.alertInvalidRequest();
            });
    };

    this.xhttpGetUploadURL = function () {

        var nbPriority = document.getElementById("Priority-Bulk-Multiline");

        if (nbPriority.value == "") {

            alert("Bulk 'Priority' field may not be empty");
        } else {

            var files = document.getElementById("Bulk-Image-Multiline").files;

            if (files.length == 1) {

                var xhttp = new XMLHttpRequest();

                xhttp.onreadystatechange = function () {

                    if (this.readyState == 4) {

                        if (this.status == 200) {

                            minimalApp.xhttpUploadFile(this.responseText);
                        } else {

                            minimalApp.alertInvalidRequest();
                        };
                    };
                };

                xhttp.open("GET", textractApiUrl);
                xhttp.send();

                minimalApp.toggleDisabledInput(true);
            } else {

                alert("Please select one file to upload.");
            };
        };
    };

    this.xhttpUploadFile = function (presignedInfoText) {

        var presignedInfoDict = JSON.parse(presignedInfoText);

        var file = document.getElementById("Bulk-Image-Multiline").files[0];

        var xhttp = new XMLHttpRequest();

        xhttp.onreadystatechange = function () {

            if (this.readyState == 4) {

                if (this.status == 204) {

                    minimalApp.xhttpAnalyzeImage(presignedInfoDict["fields"]["key"]);
                } else {

                    minimalApp.alertInvalidRequest();
                };
            };
        };

        var formData = new FormData();

        Object.entries(presignedInfoDict["fields"]).forEach(([k, v]) => {
            formData.append(k, v);
        });

        formData.append("file", file);

        // The presigned response also contains the bucket url,
        // but it can take up to 24 hours before the global url works.
        xhttp.open("POST", imageUploadBucketUrl);
        xhttp.send(formData);

        minimalApp.toggleDisabledInput(true);
    };

    this.xhttpAnalyzeImage = function (imageName) {

        var bodyText = JSON.stringify({ "name": imageName });
        var xhttp = new XMLHttpRequest();

        xhttp.onreadystatechange = function () {

            if (this.readyState == 4) {

                if (this.status == 200) {

                    var nameList = JSON.parse(this.responseText);

                    var cbRedact = document.getElementById("Redact-Bulk-Multiline");

                    if (cbRedact.checked) {

                        var taName = document.getElementById("Name-Bulk-Multiline");
                        taName.value = nameList.join("\n");

                        minimalApp.toggleDisabledInput(false);
                    } else {

                        minimalApp.parseBulkInput(nameList);
                    };
                } else {

                    minimalApp.alertInvalidRequest();
                };
            };
        };

        xhttp.open("POST", textractApiUrl);
        xhttp.send(bodyText);
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
        nameTextBox.setAttribute("onKeyPress", "minimalApp.checkSubmit(event, minimalApp.updateItemNameAndPriority, " + entryNumber + ")");
        nameCell.innerText = "";
        nameCell.appendChild(nameTextBox);

        nameTextBox.focus({ preventScroll: true });

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

            minimalApp.fetchGetTableEntries();

            mainTable.innerHTML = "";
            var tr = mainTable.insertRow(-1);
            var td = tr.insertCell(-1);
            td.innerHTML = "loading...";

            var viewDetails = document.getElementById("viewDetails");
            viewDetails.setAttribute("style", "display:block");

            var sortDetails = document.getElementById("sortDetails");
            sortDetails.setAttribute("style", "display:block");

            var bulkSimpleDetails = document.getElementById("bulkSimpleDetails");
            bulkSimpleDetails.setAttribute("style", "display:block");

            var bulkMultilineDetails = document.getElementById("bulkMultilineDetails");
            bulkMultilineDetails.setAttribute("style", "display:block");
        } else {

            minimalApp.scaleContent();
        };
    };
};

window.minimalApp = minimalApp;

minimalApp.renderPage();
