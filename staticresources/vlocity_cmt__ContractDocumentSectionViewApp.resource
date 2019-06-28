(function(){var fileNsPrefix=function(){"use strict";var scripts=document.getElementsByTagName("script");var lastScript=scripts[scripts.length-1];var scriptName=lastScript.src;var parts=scriptName.split("/");var partsLength=parts.length-1;var thisScript=parts[partsLength--];if(thisScript===""){thisScript=parts[partsLength--]}if(scriptName.indexOf("__")!=-1){while(thisScript.indexOf("__")==-1&&partsLength>=0){thisScript=parts[partsLength];partsLength--}}var lowerCasePrefix=thisScript.indexOf("__")==-1?"":thisScript.substring(0,thisScript.indexOf("__")+2);lowerCasePrefix=lowerCasePrefix===""&&localStorage.getItem("nsPrefix")?localStorage.getItem("nsPrefix"):lowerCasePrefix;if(lowerCasePrefix!==""){lowerCasePrefix=/__$/.test(lowerCasePrefix)?lowerCasePrefix:lowerCasePrefix+"__"}if(lowerCasePrefix.length===0){return function(){lowerCasePrefix=window.nsPrefix?window.nsPrefix:lowerCasePrefix;if(lowerCasePrefix!==""){lowerCasePrefix=/__$/.test(lowerCasePrefix)?lowerCasePrefix:lowerCasePrefix+"__"}return lowerCasePrefix}}else{var resolvedNs=null;return function(){if(resolvedNs){return resolvedNs}try{var tofind=lowerCasePrefix.replace("__","");var name;var scanObjectForNs=function(object,alreadySeen){if(object&&object!==window&&alreadySeen.indexOf(object)==-1){alreadySeen.push(object);Object.keys(object).forEach(function(key){if(key==="ns"){if(typeof object[key]==="string"&&object[key].toLowerCase()===tofind){name=object[key]+"__";return false}}if(Object.prototype.toString.call(object[key])==="[object Array]"){object[key].forEach(function(value){var result=scanObjectForNs(value,alreadySeen);if(result){name=result;return false}})}else if(typeof object[key]=="object"){var result=scanObjectForNs(object[key],alreadySeen);if(result){name=result;return false}}if(name){return false}});if(name){return name}}};if(typeof Visualforce!=="undefined"){scanObjectForNs(Visualforce.remoting.Manager.providers,[])}else{return lowerCasePrefix}if(name){return resolvedNs=name}else{return resolvedNs=lowerCasePrefix}}catch(e){return lowerCasePrefix}}}}();var fileNsPrefixDot=function(){var prefix=fileNsPrefix();if(prefix.length>1){return prefix.replace("__",".")}else{return prefix}};
(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var contractDocumentSectionViewApp = angular.module('contractDocumentSectionViewApp', ['vlocity', 'viaDirectives', 'mgcrea.ngStrap',
    'ngSanitize', 'ngAnimate', 'sldsangular', 'ui.tinymce', 'angularUtils.directives.dirPagination'
]).config(['remoteActionsProvider', function(remoteActionsProvider) {
    'use strict';
    remoteActionsProvider.setRemoteActions(window.remoteActions || {});
}]);

// Services
require('./modules/contractDocumentSectionViewApp/services/BrowserDetection.js');

// Controllers
require('./modules/contractDocumentSectionViewApp/controller/ContractDocumentSectionViewController.js');

// Directives
require('./modules/contractDocumentSectionViewApp/directive/CheckSectionSaved.js');

// Templates
require('./modules/contractDocumentSectionViewApp/templates/templates.js');

},{"./modules/contractDocumentSectionViewApp/controller/ContractDocumentSectionViewController.js":2,"./modules/contractDocumentSectionViewApp/directive/CheckSectionSaved.js":3,"./modules/contractDocumentSectionViewApp/services/BrowserDetection.js":4,"./modules/contractDocumentSectionViewApp/templates/templates.js":5}],2:[function(require,module,exports){
angular.module('contractDocumentSectionViewApp').controller('contractDocumentSectionViewCtrl', function($scope, $sce, $timeout,
    remoteActions, $location, browserDetection, $filter, $q, $modal) {
    'use strict';
    $scope.vlcLoading = true;

    $scope.nameSpacePrefix = '';
    if (window.nameSpacePrefix !== undefined) {
        $scope.nameSpacePrefix = window.nameSpacePrefix;
    }
    
    $scope.labels = {};
    if (window.labels !== undefined) {
        $scope.labels = window.labels;
    }

    $scope.baseRequestUrl = '';
    if (window.baseRequestUrl !== undefined) {
        $scope.baseRequestUrl = window.baseRequestUrl;
    }

    $scope.contractId = '';
    if (window.contractId !== undefined) {
        $scope.contractId = window.contractId;
    }

    $scope.sections = [];
    $scope.versionData = {
        'sections': []
    };
    $scope.validationErrors = {
        'sections': []
    };
    $scope.validationMessage = {
        'type': 'alert-success',
        'content': '',
        'error': false
    };
    $scope.alert = {
        message: '',
        type: ''
    };

    $scope.currentSectionSequence = null;
    $scope.isTemplateBatchable = true;
    $scope.statusClass = 'active';
    $scope.isTracking = false;
    $scope.isCheckIn = false;
    $scope.attachDocUrl = '';
    $scope.isConsole = sforce.console.isInConsole();
    $scope.isSforce = (typeof sforce !== 'undefined' && typeof sforce.one !== 'undefined') ? (true) : (false);
    $scope.browser = browserDetection.detectBrowser();
    $scope.isSafari = ($scope.browser === 'safari') ? true : false;
    $scope.isInternetExplorer = ($scope.browser === 'msielte10' || $scope.browser === 'msiegt10') ? true : false;
    $scope.browserVersion = browserDetection.getBrowserVersion();
    
    var documentStylesheetRef = $('link[rel=stylesheet]').filter(function() {
        return /DocumentBaseCss/.test(this.getAttribute('href'));
    });

    function refreshSuccess(result) {
        // Report whether refreshing the primary tab was successful
    }

    function showTabId(result) {
        var tabId = result.id;
        sforce.console.refreshPrimaryTabById(tabId , true, refreshSuccess);
    }

    function refreshCurrentPrimaryTab() {
        sforce.console.getFocusedPrimaryTabId(showTabId);
    }

    $scope.tinymceOptions = {
        body_class: 'vlocity',
        statusbar: false,
        selector: 'textarea.tinymce-editor', // change this value according to your HTML
        //inline: true,
        //inline_styles: true,
        schema: 'html5-strict',
        advlist_number_styles: 'default,lower-alpha,upper-alpha,lower-roman,upper-roman',
        advlist_bullet_styles: 'default,circle,square',
        style_formats: [
            {title: 'Inline', items: [
              {title: 'Bold', icon: 'bold', format: 'bold'},
              {title: 'Italic', icon: 'italic', format: 'italic'},
              {title: 'Underline', icon: 'underline', format: 'underline'},
              {title: 'Strikethrough', icon: 'strikethrough', format: 'strikethrough'},
              {title: 'Superscript', icon: 'superscript', format: 'superscript'},
              {title: 'Subscript', icon: 'subscript', format: 'subscript'}
            ]},
            {title: 'Blocks', items: [
              {title: 'Paragraph', format: 'p'}
            ]},
            {title: 'Alignment', items: [
              {title: 'Left', icon: 'alignleft', format: 'alignleft'},
              {title: 'Center', icon: 'aligncenter', format: 'aligncenter'},
              {title: 'Right', icon: 'alignright', format: 'alignright'},
              {title: 'Justify', icon: 'alignjustify', format: 'alignjustify'}
            ]}
        ],
        height: 309,
        menubar: false,
        elementpath: false,
        plugins: [
          'code advlist autolink lists link preview',
          'visualblocks visualchars',
          'table contextmenu',
          'textcolor colorpicker textpattern',
          'ice'
        ],
        ice: {
            user: {name: $scope.userName, id: $scope.userId},
            preserveOnPaste: 'p,a[href],i,em,strong,b,span',
            isTracking: false
            // Optional param - defaults to the css found in the plugin directory
            //css:
        },
        table_default_styles: {
            fontFamily: 'Times New Roman',
            fontSize: '10pt',
            width: '100%'
        },
        paste_auto_cleanup_on_paste: true,
        init_instance_callback: function(editor) {
            $(editor.getBody()).css({
                'font-size': '10pt'
            });
            editor.on('ExecCommand',function(e) {
                var val, node, nodeParent, children, i, child;
                var cmd = e.command;
                if (cmd === 'FontSize' || cmd === 'FontName') {
                    val = e.value;
                    node = e.target.selection.getNode();
                    nodeParent = node.parentNode;
                    if (node.nodeName === 'SPAN' && nodeParent.nodeName === 'LI') {
                        children = $(node).children('li');
                        if (children) {
                            children.removeAttr('data-mce-style');
                            if (cmd === 'FontSize') {
                                children.css('font-size',val);
                                $(node.parentNode).css('font-size',val);
                            }
                            if (cmd === 'FontName') {
                                children.css('font-family',val);
                                $(node.parentNode).css('font-family',val);
                            }
                        }
                    } else if (node.nodeName === 'OL' || node.nodeName === 'UL') {
                        children = node.children;
                        for (i = 0; i < children.length; i++) {
                            child = $(children[i]);
                            child.removeAttr('data-mce-style');
                            if (cmd === 'FontSize') {
                                child.css('font-size',val);
                            }
                            if (cmd === 'FontName') {
                                child.css('font-family',val);
                            }
                        }
                    }
                }
            });
        },
        browser_spellcheck: true,
        toolbar1:'undo redo | styleselect | bold italic underline | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link code',
        toolbar2:'preview | forecolor backcolor | table | fontselect fontsizeselect | ice_toggleshowchanges iceacceptall iceaccept icerejectall icereject',
        //content_css: documentStylesheetRef[0].getAttribute('href'),
        fontsize_formats: '6pt 7pt 8pt 9pt 10pt 11pt 12pt 14pt 16pt 18pt 20pt 22pt 24pt 30pt 36pt'
    };

    // Get Section View Data
    $scope.getSectionViewData = function() {
        var inputData = {
            'contractId': $scope.contractId
        };
        remoteActions.getSectionViewData(inputData).then(function(result) {
            var i, tempValidationObj;
            console.log('Section View Data:', result);

            $scope.contractVersion = result.contractVersion;
            $scope.isTemplateBatchable = $scope.contractVersion[$scope.nameSpacePrefix + 'IsTemplateBatchable__c'];
            
            for (i = 0; i < result.contractSections.length; i++) {
                $scope.sections.push(result.contractSections[i]);

                tempValidationObj = {
                    'sectionName': '',
                    'sectionContent': '',
                    'sectionSaved': true,
                    'sectionErrors': false
                };
                $scope.validationErrors.sections.push(tempValidationObj);
            }
            console.log($scope.versionData);
            $timeout(function() {
                $scope.vlcLoading = false;
            }, 1000);
        }, function(error) {
            $scope.validationErrorHandler(error);
        });
    };
    
    this.$onInit = function() {
        $scope.getSectionViewData();
    };

    $scope.showSectionContent = function(section) {
        var signatureContent, signatureSplit, i;
        $scope.vlcLoading = true;
        $scope.validationMessage.content = '';
        $scope.validationMessage.error = false;

        if (section.type === 'Custom' || section.content) {
            $scope.displaySectionContent(section);
        } else {
            $scope.getSectionContent(section);
        }
    };

    $scope.displaySectionContent = function(section) {
        if (section.type === 'Custom') {
            $scope.showContentEditor = false;
        } else {
            $scope.showContentEditor = true;
            $scope.tinymceOptions.readonly = section.isRestricted;
        }

        $scope.currentSectionSequence = section.sequence;
        $scope.vlcLoading = false;
    };

    $scope.getSectionContent = function(section) {
        var inputData = {
            'sectionId': section.sectionId
        };
        remoteActions.getSectionContent(inputData).then(function(result) {
            section.content = result.sectionContent;

            if ($scope.isInternetExplorer && section.content.indexOf('padding-left: 0px; width: 100%; display: inline-block;') > -1) {
                section.content = section.content.replace('padding-left: 0px; width: 100%; display: inline-block;', 'padding-left: 0px; width: 100%; display: block;');
            }
            $scope.removeWrappers(section);
            $scope.formatSectionContent(section);
            
            $scope.displaySectionContent(section);
        }, function(error) {
            $scope.validationErrorHandler(error);
            $scope.vlcLoading = false;
        });
    };

    // helper method to strip span tags out of section content when loading the UI
    $scope.removeWrappers = function(section) {
        var htmlTagRegex, sectionContentArray, tempSectionContent, i;
        if (section.content) {
            htmlTagRegex = /(<[^>]*>)/;
            sectionContentArray = section.content.split(htmlTagRegex);
            tempSectionContent = '';
            for (i = 0; i < sectionContentArray.length; i++) {
                if (sectionContentArray[i] !== '<viawrapper>' && sectionContentArray[i] !== '</viawrapper>') {
                    tempSectionContent = tempSectionContent + sectionContentArray[i];
                }
            }
            section.content = tempSectionContent;
        }
    };

    $scope.formatSectionContent = function(section) {
        if (section.type === 'Item') {
            //$scope.formatProductSection(section); // TODO: what is this doing?
        }
        if (section.type === 'Signature') {
            // Remove signature strings between \ and \
            signatureContent = section.content;
            
            // split string at anything starting with \
            signatureSplit = signatureContent.split(/(?=\\)/);
            for (i = 0; i < signatureSplit.length; i++) {
                if (signatureSplit[i].charAt(0) === '\\') {
                    // if we reach a word starting with \, remove it:
                    signatureContent = signatureContent.replace(signatureSplit[i] + '\\', '');
                }
            }
            
            section.content = signatureContent;
            //$scope.formatSignatureSection(sequence); // TODO: what should be done here?
        }
    };

    $scope.formatProductSection = function(sequence) {
        remoteActions.formatProductSection($scope.originalSectionData.documentSectionObjs[sequence]).then(function(result) {
            $scope.versionData.sections[sequence].formattedLineItemTable = result;
        }, function(error) {
            $scope.validationErrorHandler(error);
        });
    };
 
    $scope.formatSignatureSection = function(sequence) {
        remoteActions.formatSignatureSection(angular.toJson($scope.versionData.sections[sequence].sectionContent)).then(function(result) {
            $scope.versionData.sections[sequence].sectionContent = result;
        }, function(error) {
            $scope.validationErrorHandler(error);
        });
    };

    // Save current section:
    $scope.saveTemplateSection = function(sequence) {
        var i;
        // Validate first
        $scope.validateSection(sequence);
        if ($scope.validationErrors.sectionValid) {
            // Once saved, this section immediately gets flagged as 'non-standard':
            $scope.versionData.sections[sequence].sectionNonStandard = true;
            // Add wrappers for saving & assign new data back into originalSectionData so it is saved properly:
            $scope.insertWrappers(sequence);
            // Assign data back into expected DocumentContentStructure format (previously cached):
            $scope.originalSectionData.documentSectionObjs[sequence].Id = $scope.versionData.sections[sequence].sectionId;
            $scope.originalSectionData.documentSectionObjs[sequence][$scope.nameSpacePrefix + 'IsRestricted__c'] = $scope.versionData.sections[sequence].sectionIsRestricted;
            $scope.originalSectionData.documentSectionObjs[sequence].Name = $scope.versionData.sections[sequence].sectionName;
            $scope.originalSectionData.documentSectionObjs[sequence][$scope.nameSpacePrefix + 'DisplayHeaderData__c'] =
            $scope.updateDisplayHeader(sequence, $scope.versionData.sections[sequence].sectionName);
            $scope.originalSectionData.documentSectionObjs[sequence][$scope.nameSpacePrefix + 'SectionContent__c'] = $scope.versionData.sections[sequence].sectionContent;
            $scope.originalSectionData.documentSectionObjs[sequence][$scope.nameSpacePrefix + 'Sequence__c'] = $scope.versionData.sections[sequence].sectionSequence;
            $scope.originalSectionData.documentSectionObjs[sequence][$scope.nameSpacePrefix + 'Type__c'] = $scope.versionData.sections[sequence].sectionType;
            $scope.originalSectionData.documentSectionObjs[sequence][$scope.nameSpacePrefix + 'IsSectionNonStandard__c'] = $scope.versionData.sections[sequence].sectionNonStandard;
            $scope.vlcLoading = true;
            remoteActions.saveTemplateSection($scope.originalSectionData.documentSectionObjs[sequence]).then(function() {
                // Move the right-col scroll to top so we can actually see the validation msg:
                document.getElementsByClassName('right-col')[0].scrollTop = 0;
                $scope.validationErrors.sections[sequence].sectionSaved = true;
                $scope.validationErrors.sections[sequence].sectionErrors = false;
                $scope.removeWrappers(sequence);
                $scope.validationMessage.type = 'alert-success';
                $scope.validationMessage.content = 'Section saved successfully.';
                $scope.validationMessage.error = false;
                $scope.vlcLoading = false;
            }, function(error) {
                $scope.validationErrorHandler(error);
            });
        }
    };

    // Helper method to add spans into sectionContent before it is saved to the db:
    $scope.insertWrappers = function(sequence) {
        if ($scope.versionData.sections[sequence].sectionContent) {
            $scope.versionData.sections[sequence].sectionContent = $scope.insertViawrappers($scope.versionData.sections[sequence].sectionContent);

            // Check sectionContent to see if the wrapper div exists with document styling:
            if ($scope.versionData.sections[sequence].sectionContent.indexOf('section-content-wrapper') < 0) {
                $scope.versionData.sections[sequence].sectionContent = '<div class="section-content-wrapper" style="font-size: 10pt;">' +
                    $scope.versionData.sections[sequence].sectionContent + '</div>';
            }
        }

        if ($scope.versionData.sections[sequence].sectionDisplayHeader) {
            $scope.versionData.sections[sequence].sectionDisplayHeader = $scope.insertViawrappers($scope.versionData.sections[sequence].sectionDisplayHeader);
        }
    };

    // Helper method to add spans into sectionContent before it is saved to the db for console:
    $scope.insertWrappersConsole = function(sequence) {
        var versionData = document.getElementById('customizeDoc').contentWindow.angular.element('.vlocity').scope().versionData;
        if (versionData.sections[sequence].sectionContent) {
            versionData.sections[sequence].sectionContent = $scope.insertViawrappers(versionData.sections[sequence].sectionContent);

            // Check sectionContent to see if the wrapper div exists with document styling:
            if (versionData.sections[sequence].sectionContent.indexOf('section-content-wrapper') < 0) {
                versionData.sections[sequence].sectionContent = '<div class="section-content-wrapper" style="font-size: 10pt;">' +
                    versionData.sections[sequence].sectionContent + '</div>';
            }
        }

        if (versionData.sections[sequence].sectionDisplayHeader) {
            versionData.sections[sequence].sectionDisplayHeader = $scope.insertViawrappers($scope.versionData.sections[sequence].sectionDisplayHeader);
        }
    };

    //Help method to add viawrapper
    $scope.insertViawrappers = function(content) {
        var trimmedContent, htmlTagRegex, i, contentArray, charCode;
        if (content) {
            //Replace all occurrences of &nbsp; with ' ' except when immediately preceded by <p> and immediately followed by </p>
            trimmedContent = content.replace(/&nbsp;/g, ' ').replace(/<p>\s<\/p>/g, '<p>&nbsp;</p>');
            htmlTagRegex = /(<[^>]*>)/;
            contentArray = trimmedContent.split(htmlTagRegex);

            //wrap viawrapper around all text in content
            trimmedContent = '';
            for (i = 0; i < contentArray.length; i++) {
                charCode = contentArray[i].charCodeAt(0);
                if (contentArray[i] !== '' && contentArray[i].charAt(0) !== '<' &&
                    contentArray[i].slice(-1) !== '>' && charCode !== 10) {
                    contentArray[i] = '<viawrapper>' + contentArray[i] + '</viawrapper>';
                }
                if (i > 0) {
                    trimmedContent = trimmedContent + contentArray[i];
                }
            }
        }
        //console.log('after wrapping with viawrapper: ' + trimmedContent );
        return trimmedContent;
    };

    // Used to validate sectionContent to make sure there is real text available, not just HTML code
    $scope.stripHtml = function(html) {
        var tmp = document.createElement('div');
        tmp.innerHTML = html;
        return tmp.textContent || tmp.innerText || '';
    };

    // Validate a section
    $scope.validateSection = function(sequence) {
        // Reset template sections errors:
        $scope.validationErrors.sections[sequence].sectionName = '';
        $scope.validationErrors.sections[sequence].sectionContent = '';

        // Innocent until proven guilty:
        $scope.validationErrors.sectionValid = true;
        $scope.validationErrors.sections[sequence].sectionErrors = false;

        // Check Current Section Name is not empty:
        if ($scope.versionData.sections[sequence] && !$scope.versionData.sections[sequence].sectionName) {
            $scope.validationErrors.sections[sequence].sectionName = 'Please enter a Section Name.';
            $scope.validationErrors.sections[sequence].sectionErrors = true;
            $scope.validationErrors.sectionValid = false;
        }
        // Check Current Section Content is not empty:
        if ($scope.versionData.sections[sequence] && $scope.versionData.sections[sequence].sectionType !== 'Conditional' &&
            $scope.versionData.sections[sequence].sectionType !== 'Embedded Template') {
            if ($scope.versionData.sections[sequence].sectionContent.indexOf('<img') < 0 && /\S/.test($scope.stripHtml($scope.versionData.sections[sequence].sectionContent)) === false) {
                $scope.validationErrors.sections[sequence].sectionContent = 'Please enter Section Content text.';
                $scope.validationErrors.sections[sequence].sectionErrors = true;
                $scope.validationErrors.sectionValid = false;
            }
        }

        // Check Current Section Content is not empty:
        if ($scope.versionData.sections[sequence].sectionType === 'Item' && $scope.versionData.sections[sequence].sectionLineItems !== undefined) {
            $scope.validationErrors.sections[sequence].sectionContent = 'Please enter Section Content.';
            $scope.validationErrors.sections[sequence].sectionErrors = true;
            $scope.validationErrors.sectionValid = false;
        }
    };

    // Error handling helper
    $scope.validationErrorHandler = function(error) {
        if (!error.message) {
            error.message = 'No error message.';
        }
        if (typeof error.type === 'string') {
            error.type = error.type.capitalizeFirstLetter();
        }
        $scope.validationMessage.type = 'alert-danger';
        $scope.validationMessage.content = error.type + ' (' + error.statusCode + '): ' + error.message;
        $scope.validationMessage.error = true;
        $scope.vlcLoading = false;
    };

    // Adding to String prototype
    String.prototype.capitalizeFirstLetter = function() {
        return this.charAt(0).toUpperCase() + this.slice(1);
    };

    $scope.trustAsHtml = function(string) {
        return $sce.trustAsHtml(string);
    };

    $scope.navigateBack = function() {
        $modal({
            title: $scope.labels.checkInDocLabel + ' ?',
            templateUrl: 'checkin-modal.tpl.html',
            html: true,
            scope: $scope,
            container: 'div.vlocity',
            placement: 'center',
            prefixEvent: 'checkinModal',
            backdrop: false
        });
    };

    $scope.navigateBackConsole = function() {
        $modal({
            title: $scope.labels.checkInDocLabel + ' ?',
            templateUrl: 'checkin-console-modal.tpl.html',
            html: true,
            scope: $scope,
            container: 'div.vlocity',
            placement: 'center',
            prefixEvent: 'checkinModal',
            backdrop: false
        });
    };

    $scope.goBack = function() {
        $scope.vlcLoading = true;
        if ($scope.isConsole) {
            // close current tab
            sforce.console.getEnclosingTabId(function(result) {
                var tabId = result.id;
                sforce.console.closeTab(tabId);
            });
            // refocus primary tab
            refreshCurrentPrimaryTab();
        } else {
            if (!$scope.isSforce) {
                window.top.location.href = $scope.baseRequestUrl + '/' + $scope.contractId;
                return false;
            } else if ($scope.isSforce) {
                sforce.one.navigateToURL($scope.baseRequestUrl + '/' + $scope.contractId);
            }
        }
    };

    $scope.gotoPageView = function() {       
        location.href = location.origin + '/apex/' + nameSpacePrefix + 'ContractDocumentEditSections?Id=' + $scope.contractId;
    };

    $scope.clearAlert = function() {
        $scope.alert.message = '';
        $scope.alert.type = '';
    };
});

},{}],3:[function(require,module,exports){
angular.module('contractDocumentSectionViewApp').directive('checkSectionSaved', function() {
    'use strict';
    function compareObjects(s, t) {
        var prop;
        if (typeof s !== typeof t) {
            console.log('two objects not the same type');
            return;
        }
        if (typeof s !== 'object') {
            console.log('arguments are not typeof === "object"');
            return;
        }
        for (prop in s) {
            if (s.hasOwnProperty(prop)) {
                if (t.hasOwnProperty(prop)) {
                    if (!angular.equals(s[prop], t[prop])) {
                        console.log('property ' + prop + ' does not match');
                    }
                } else {
                    console.log('second object does not have property ' + prop);
                }
            }
        }
        // now verify that t doesn't have any properties
        // that are missing from s
        for (prop in t) {
            if (t.hasOwnProperty(prop)) {
                if (!s.hasOwnProperty(prop)) {
                    console.log('first object does not have property ' + prop);
                }
            }
        }
    }
    return {
        restrict: 'E',
        scope: {
            validationErrors: '=',
            btnText: '=',
            docSection: '=',
            docTemplateIsActive: '='
        },
        link: function(scope) {
            scope.$watch('docSection', function(newValue, oldValue) {
                if (newValue.content) {
                    scope.$parent.removeWrappers(scope.docSection.sequence);
                    if (newValue.sectionType === 'Embedded Template') {
                        return;
                    }
                    // tinymce inserts \n linebreaks in the code for their code view which disrupts the data. Ignore.
                    if (oldValue.content) {
                        if ((oldValue.content.match(/\n/g) || []).length !== (newValue.content.match(/\n/g) || []).length) {
                            return;
                        }
                    }
                }

                // Need to only do this on subsequent saves to a section
                if (oldValue.content && angular.equals(newValue, oldValue) === false) {
                    scope.validationErrors.sections[scope.docSection.sequence].sectionSaved = false;
                }
            }, true);
        }
    };
});

},{}],4:[function(require,module,exports){
(function() {
    'use strict';
    window.angular.module('contractDocumentSectionViewApp').service('browserDetection', ['$window', function($window) {
        this.userAgent = $window.navigator.userAgent;
        this.browsers = {
            chrome: /chrome/i,
            safari: /safari/i,
            firefox: /firefox/i,
            msielte10: /msie/i,
            msiegt10: /rv:/i,
            edge: /edge/i
        };

        this.detectBrowser = function() {
            var key;
            var userAgent = this.userAgent;
            var browsers = this.browsers;
            for (key in browsers) {
                if (browsers[key].test(userAgent)) {
                    return key;
                }
            }
            return 'unknown';
        };

        this.getBrowserVersion = function() {
            var version, i;
            var browser = this.detectBrowser();
            var userAgent = this.userAgent;
            var versionSearch = [{
                browser: 'chrome',
                before: ' ',
                after: 'Chrome/'
            }, {
                browser: 'safari',
                before: ' ',
                after: 'Version/'
            }, {
                browser: 'firefox',
                before: '',
                after: 'Firefox/'
            }, {
                browser: 'msielte10',
                before: ';',
                after: 'MSIE '
            }, {
                browser: 'msiegt10',
                before: ')',
                after: 'rv:'
            }, {
                browser: 'edge',
                before: '',
                after: 'Edge/'
            }];

            for (i = 0; i < versionSearch.length; i++) {
                if (browser === versionSearch[i].browser) {
                    version = userAgent.split(versionSearch[i].after)[1];
                    if (versionSearch[i].before) {
                        version = parseFloat(version.substr(0, version.indexOf(versionSearch[i].before)));
                    }
                }
            }

            return version;
        };
    }]);
}());

},{}],5:[function(require,module,exports){
angular.module("contractDocumentSectionViewApp").run(["$templateCache",function($templateCache){"use strict";$templateCache.put("checkin-console-modal.tpl.html",'<div class="slds-modal slds-fade-in-open" tabindex="-1" role="dialog">\n    <div class="slds-modal__container">\n        <div class="slds-modal__header">\n           <button class="slds-button slds-button_icon-inverse slds-modal__close" ng-click="$hide();">\n                <slds-svg-icon id="close" sprite="\'action\'" icon="\'close\'" size="\'medium\'"></slds-svg-icon>\n            </button>\n            <h4 class="slds-text-heading_medium slds-m-bottom_none" ng-bind-html="title"></h4>\n        </div>\n        <div class="slds-modal__content slds-p-around_medium">\n            <div>\n                <p>{{labels.customizeReadyCheckInLabel}}</p>\n            </div>\n        </div>\n        <div class="slds-modal__footer">\n            <button type="button" class="slds-button slds-button_neutral modal-back-btn" ng-click="goBack(); $hide()">{{labels.noCheckInLabel}}</button>\n            <button type="button" class="slds-button slds-button_neutral modal-cancel-btn" ng-click="$hide()">{{labels.cancelLabel}}</button>\n            <button type="button" class="slds-button slds-button_brand modal-check-in-btn" ng-click="checkInDocumentConsole(); $hide();">{{labels.yesCheckInLabel}}</button>\n        </div>\n    </div>\n</div>\n<div class="slds-backdrop slds-backdrop_open"></div>'),$templateCache.put("checkin-modal.tpl.html",'<div class="slds-modal slds-fade-in-open" tabindex="-1" role="dialog">\n    <div class="slds-modal__container">\n        <div class="slds-modal__header">\n           <button class="slds-button slds-button_icon-inverse slds-modal__close" ng-click="$hide();">\n                <slds-svg-icon id="clause-page-header_icon" sprite="\'action\'" icon="\'close\'" size="\'medium\'"></slds-svg-icon>\n            </button>\n            <h4 class="slds-text-heading_medium slds-m-bottom_none" ng-bind-html="title"></h4>\n        </div>\n        <div class="slds-modal__content slds-p-around_medium">\n            <div>\n                <p>{{labels.customizeReadyCheckInLabel}}</p>\n            </div>\n        </div>\n        <div class="slds-modal__footer">\n            <button type="button" class="slds-button slds-button_neutral modal-back-btn" ng-click="goBack(); $hide()">{{labels.noCheckInLabel}}</button>\n            <button type="button" class="slds-button slds-button_neutral modal-cancel-btn" ng-click="$hide()">{{labels.cancelLabel}}</button>\n            <button type="button" class="slds-button slds-button_brand modal-check-in-btn" ng-click="checkInDocument(); $hide();">{{labels.yesCheckInLabel}}</button>\n        </div>\n    </div>\n</div>\n<div class="slds-backdrop slds-backdrop_open"></div>'),$templateCache.put("dir-pagination-controls.tpl.html",'<ul class="pagination" ng-if="1 < pages.length">\n    <li ng-if="boundaryLinks" ng-class="{ disabled : pagination.current == 1 }">\n        <a href="" ng-click="setCurrent(1)">&laquo;</a>\n    </li>\n    <li ng-if="directionLinks" ng-class="{ disabled : pagination.current == 1 }">\n        <a href="" ng-click="setCurrent(pagination.current - 1)">&lsaquo;</a>\n    </li>\n    <li ng-repeat="pageNumber in pages track by $index" ng-class="{ active : pagination.current == pageNumber, disabled : pageNumber == \'...\' }">\n        <a href="" ng-click="setCurrent(pageNumber)">{{ pageNumber }}</a>\n    </li>\n\n    <li ng-if="directionLinks" ng-class="{ disabled : pagination.current == pagination.last }">\n        <a href="" ng-click="setCurrent(pagination.current + 1)">&rsaquo;</a>\n    </li>\n    <li ng-if="boundaryLinks"  ng-class="{ disabled : pagination.current == pagination.last }">\n        <a href="" ng-click="setCurrent(pagination.last)">&raquo;</a>\n    </li>\n</ul>'),$templateCache.put("docx-contains-redlines-modal.tpl.html",'<div class="slds-modal slds-fade-in-open" tabindex="-1" role="dialog">\n    <div class="slds-modal__container">\n        <div class="slds-modal__header">\n           <button class="slds-button slds-button_icon-inverse slds-modal__close" ng-click="$hide();">\n                <slds-svg-icon id="clause-page-header_icon" sprite="\'action\'" icon="\'close\'" size="\'medium\'"></slds-svg-icon>\n            </button>\n            <h4 class="slds-text-heading_medium slds-m-bottom_none" ng-bind-html="title"></h4>\n        </div>\n        <div class="slds-modal__content slds-p-around_medium">\n            <div>\n                <p>{{labels.downloadDocRedlineLabel}}</p>\n            </div>\n        </div>\n        <div class="slds-modal__footer">\n            <button type="button" class="slds-button slds-button_neutral modal-cancel-btn" ng-click="$hide()">{{labels.cancelLabel}}</button>\n            <button type="button" class="slds-button slds-button_brand modal-download-btn" ng-click="downloadDocx(); $hide();">{{labels.yesDownloadLabel}}</button>\n        </div>\n    </div>\n</div>\n<div class="slds-backdrop slds-backdrop_open"></div>'),$templateCache.put("pdf-contains-redlines-modal.tpl.html",'<div class="slds-modal slds-fade-in-open" tabindex="-1" role="dialog">\n    <div class="slds-modal__container">\n        <div class="slds-modal__header">\n           <button class="slds-button slds-button_icon-inverse slds-modal__close" ng-click="$hide();">\n                <slds-svg-icon id="clause-page-header_icon" sprite="\'action\'" icon="\'close\'" size="\'medium\'"></slds-svg-icon>\n            </button>\n            <h4 class="slds-text-heading_medium slds-m-bottom_none" ng-bind-html="title"></h4>\n        </div>\n        <div class="slds-modal__content slds-p-around_medium">\n            <div>\n                <p>{{labels.downloadDocRedlineLabel}}</p>\n            </div>\n        </div>\n        <div class="slds-modal__footer">\n            <button type="button" class="slds-button slds-button_neutral modal-cancel-btn" ng-click="$hide()">{{labels.cancelLabel}}</button>\n            <button type="button" class="slds-button slds-button_brand modal-download-btn" ng-click="downloadPdf(); $hide();">{{labels.yesDownloadLabel}}</button>\n        </div>\n    </div>\n</div>\n<div class="slds-backdrop slds-backdrop_open"></div>')}]);
},{}]},{},[1]);

})();