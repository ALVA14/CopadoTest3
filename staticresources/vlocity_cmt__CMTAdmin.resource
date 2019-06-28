(function(){var fileNsPrefix=function(){"use strict";var scripts=document.getElementsByTagName("script");var lastScript=scripts[scripts.length-1];var scriptName=lastScript.src;var parts=scriptName.split("/");var partsLength=parts.length-1;var thisScript=parts[partsLength--];if(thisScript===""){thisScript=parts[partsLength--]}if(scriptName.indexOf("__")!=-1){while(thisScript.indexOf("__")==-1&&partsLength>=0){thisScript=parts[partsLength];partsLength--}}var lowerCasePrefix=thisScript.indexOf("__")==-1?"":thisScript.substring(0,thisScript.indexOf("__")+2);lowerCasePrefix=lowerCasePrefix===""&&localStorage.getItem("nsPrefix")?localStorage.getItem("nsPrefix"):lowerCasePrefix;if(lowerCasePrefix!==""){lowerCasePrefix=/__$/.test(lowerCasePrefix)?lowerCasePrefix:lowerCasePrefix+"__"}if(lowerCasePrefix.length===0){return function(){lowerCasePrefix=window.nsPrefix?window.nsPrefix:lowerCasePrefix;if(lowerCasePrefix!==""){lowerCasePrefix=/__$/.test(lowerCasePrefix)?lowerCasePrefix:lowerCasePrefix+"__"}return lowerCasePrefix}}else{var resolvedNs=null;return function(){if(resolvedNs){return resolvedNs}try{var tofind=lowerCasePrefix.replace("__","");var name;var scanObjectForNs=function(object,alreadySeen){if(object&&object!==window&&alreadySeen.indexOf(object)==-1){alreadySeen.push(object);Object.keys(object).forEach(function(key){if(key==="ns"){if(typeof object[key]==="string"&&object[key].toLowerCase()===tofind){name=object[key]+"__";return false}}if(Object.prototype.toString.call(object[key])==="[object Array]"){object[key].forEach(function(value){var result=scanObjectForNs(value,alreadySeen);if(result){name=result;return false}})}else if(typeof object[key]=="object"){var result=scanObjectForNs(object[key],alreadySeen);if(result){name=result;return false}}if(name){return false}});if(name){return name}}};if(typeof Visualforce!=="undefined"){scanObjectForNs(Visualforce.remoting.Manager.providers,[])}else{return lowerCasePrefix}if(name){return resolvedNs=name}else{return resolvedNs=lowerCasePrefix}}catch(e){return lowerCasePrefix}}}}();var fileNsPrefixDot=function(){var prefix=fileNsPrefix();if(prefix.length>1){return prefix.replace("__",".")}else{return prefix}};
(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
'use strict';
var app = angular.module('CMTAdmin', ['vlocity', 'sldsangular','epcadmin', 'fieldLookupUI', 'ngSanitize', 'ngAnimate']);
app.config(['remoteActionsProvider', function(remoteActionsProvider) {
    remoteActionsProvider.setRemoteActions(window.remoteActions || {});
}]);

require('./modules/CMTAdmin/controller/CMTAdminController.js');
require('./modules/CMTAdmin/controller/DashboardController.js');
require('./modules/CMTAdmin/controller/AdminConsoleController.js');
require('./modules/CMTAdmin/controller/CustomSettingsController.js');
require('./modules/CMTAdmin/controller/EnableFeaturesController.js');
require('./modules/CMTAdmin/factory/BasicFactory.js');
require('./modules/CMTAdmin/factory/BasicService.js');
require('./modules/CMTAdmin/templates/templates.js');

},{"./modules/CMTAdmin/controller/AdminConsoleController.js":2,"./modules/CMTAdmin/controller/CMTAdminController.js":3,"./modules/CMTAdmin/controller/CustomSettingsController.js":4,"./modules/CMTAdmin/controller/DashboardController.js":5,"./modules/CMTAdmin/controller/EnableFeaturesController.js":6,"./modules/CMTAdmin/factory/BasicFactory.js":7,"./modules/CMTAdmin/factory/BasicService.js":8,"./modules/CMTAdmin/templates/templates.js":9}],2:[function(require,module,exports){
var app = angular.module('CMTAdmin');
app.controller('AdminConsoleController', ['$scope', '$window', '$timeout', '$sldsModal', 'BasicService', 'remoteActions', '$window', 'ActiveMenu', '$sldsToast',
	function (scope, window, timeout, modal, basicService, remoteActions, window, activeMenu, sldsToast) {
		scope.asyncApexJobFieldsLabels = window.asyncApexJobFieldsLabels;
		scope.labels = window.labels;
		scope.configData = window.configData;
		scope.module = {};
		scope.activeMenu = 0;
		scope.rootAccountJobsList = [];
        scope.translationJobsList = [];
		scope.XLIBatchJobValidationList = [];
		scope.refreshPriceBookJobList = [];
		scope.upgradeTab = {};
		scope.upgradeTab.attributesBindingObjects = null;
        scope.configResult = {};
        scope.translationCacheJobsList = {};
		scope.jobWrapper = {};

		scope.initApp = function(name, label) {
			scope.module.name = name;
			scope.module.label = label;
			scope.$parent.spinner.showSpinner();
			scope.refreshBatchJobLists();
			scope.$parent.spinner.hideSpinner();
			scope.initializeJobWrapper();
		};

        scope.startTranslationJob = function() {
            var parameters = {};
            parameters.methodName =  "startTranslationJob";
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
            remoteOptions.parameters =  JSON.stringify(parameters);
            var toast = basicService.infoToast(labels.CreateTranslationJobLabel, labels.StartingLabel);
            remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
                toast.hide();
                if(result.hasErrors) {
                    //show errors
                    basicService.errorToast(labels.CreateTranslationJobLabel, result.errorMessage);
                } else {
                    scope.translationJobsList = result.translationJobs;
                    basicService.successToast(labels.CreateTranslationJobLabel, labels.RunningLabel);
                }
            }, function(error) {
                toast.hide();
                basicService.errorToast(labels.CreateTranslationJobLabel, labels.CouldntStartLabel);
            });
        };
        scope.startTranslationCacheJob = function() {
            var parameters = {};
            parameters.methodName =  "startTranslationCacheJob";
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
            remoteOptions.parameters =  JSON.stringify(parameters);
            var toast = basicService.infoToast(labels.CreateTranslationCacheJobLabel, labels.StartingLabel);
            remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
                toast.hide();
                if(result.hasErrors) {
                    //show errors
                    basicService.errorToast(labels.CreateTranslationCacheJobLabel, result.errorMessage);
                } else {
                    scope.translationCacheJobsList = result.translationCacheJobs;
                    basicService.successToast(labels.CreateTranslationCacheJobLabel, labels.RunningLabel);
                }
            }, function(error) {
                toast.hide();
                basicService.errorToast(labels.CreateTranslationCacheJobLabel, labels.CouldntStartLabel);
            });
        };

		scope.initializeJobWrapper = function() {
			scope.jobWrapper.startRootAccountJob = {
									callBack: scope.startRootAccountJob,
									jobListToggle: false,
									label: scope.labels.AccountHierarchyMaintenance
								};
			scope.jobWrapper.resetInterfaceImplementations = {
									callBack: scope.resetInterfaceImplementations,
									jobListToggle: false,
									label: scope.labels.InterfaceImplementationMaintenanceRestore
								};
			scope.jobWrapper.mergeInterfaceImplementations = {
									callBack: scope.mergeInterfaceImplementations,
									jobListToggle: false,
									label: scope.labels.InterfaceImplementationMaintenanceMerge
								};
			scope.jobWrapper.resetFieldMaps = {
									callBack: scope.resetFieldMaps,
									jobListToggle: false,
									label: scope.labels.FieldMapsMaintenance
								};
			scope.jobWrapper.resetObjectMaps = {
									callBack: scope.resetObjectMaps,
									jobListToggle: false,
									label: scope.labels.ObjectMapMaintenance
								};
			scope.jobWrapper.startXLIBatchValidationJob = {
									callBack: scope.startXLIBatchValidationJob,
									jobListToggle: false,
									label: scope.labels.BatchValidation
								};
			scope.jobWrapper.resetXLIBatchValidationData = {
									callBack: scope.resetXLIBatchValidationData,
									jobListToggle: false,
									label: scope.labels.ResetXLIValiatonData
								};
			scope.jobWrapper.startProductHierarchyJob = {
									callBack: scope.startProductHierarchyJob,
									jobListToggle: false,
									label: scope.labels.ProductHierarchyMaintenanceTitle
								};
			scope.jobWrapper.clearPlatformCache = {
									callBack: scope.clearPlatformCache,
									jobListToggle: false,
									label: scope.labels.ClearManagedPlatformCache
								};
			scope.jobWrapper.refreshPriceBook = {
									callBack: scope.refreshPriceBook,
									jobListToggle: false,
									label: scope.labels.RefreshPricebook
								};
		}

		scope.confirmationPopup = function(jobType) {
			var modalScope = scope.$new();
			modalScope.confirmActionLbl = scope.labels.OKLabel;
            modalScope.confirmationMsg = scope.labels.MaintenanceJobRunWarning;
            modalScope.confirmationTitle = jobType.label;
            modalScope.cancelActionLbl = scope.labels.CancelLabel;
            modalScope.SLDSICON = scope.SLDSICON;
            modalScope.confirmAction = function() {
            	jobType.jobListToggle = true;
            	confirmModal.hide();
            	jobType.callBack();
            };
            var confirmModal = modal({
                templateUrl: 'ConfirmationModal.tpl.html',
                backdrop: 'static',
                scope: modalScope,
                show: true
            });
		}

		scope.startRootAccountJob = function() {
			var parameters = {};
        	parameters.methodName =  "startRootAccountJob";
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
        	remoteOptions.parameters =  JSON.stringify(parameters);
        	var toast = basicService.infoToast(labels.ResolveRootAccounts, labels.StartingLabel);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				scope.rootAccountJobsList = result.resolveRootAccountsJobs;
				toast.hide();
				basicService.successToast(labels.ResolveRootAccounts, labels.RunningLabel);
			}, function(error) {
				toast.hide();
				basicService.errorToast(labels.ResolveRootAccounts, labels.CouldntStartLabel);
			});
		};

		scope.startAttributesBindingJob = function() {
			var parameters = {};
        	parameters.methodName =  "startAttributesBindingJob";
        	parameters.objectNames =  scope.upgradeTab.attributesBindingObjects;
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
        	remoteOptions.parameters =  JSON.stringify(parameters);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				scope.attributesBindingJobsList = result.attributesBindingJobs;

			});
		};

		// validate the startAttributesBindingJob form
		scope.validateInput = function() {
			if(scope.upgradeTab.attributesBindingObjects != null){
				return false;
			}else{
				return true;
			}
		};

		scope.startRootProductChildItemJob = function() {
			var parameters = {};
        	parameters.methodName =  "startRootProductChildItemJob";
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
        	remoteOptions.parameters =  JSON.stringify(parameters);
        	var toast = basicService.infoToast(labels.RootPCIUpgrade, labels.StartingLabel);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				scope.rootProductChildItemJobsList = result.rootProductChildItemJobs;
				toast.hide();
				basicService.successToast(labels.RootPCIUpgrade, labels.RunningLabel);
			});
		};

		scope.startXLIBatchValidationJob = function() {
			var parameters = {};
        	parameters.methodName =  "startXLIBatchValidationJob";
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
        	remoteOptions.parameters =  JSON.stringify(parameters);
        	var toast = basicService.infoToast(labels.StartBatchJobValidation, labels.StartingLabel);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				scope.XLIBatchJobValidationList = result.xliBatchValidationJobs;
				toast.hide();
				basicService.successToast(labels.StartBatchJobValidation, labels.RunningLabel);
			});
		};

		scope.resetXLIBatchValidationData = function() {
			var parameters = {};
        	parameters.methodName =  "resetXLIBatchValidtionData";
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
        	remoteOptions.parameters =  JSON.stringify(parameters);
        	var toast = basicService.infoToast(labels.ResetXLIValiatonData, labels.RunningLabel);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				toast.hide();
				if(result.hasErrors) {
					basicService.errorToast(labels.ResetXLIValiatonData, result.errorMessage);
				} else {
					basicService.successToast(labels.ResetXLIValiatonData, labels.SuccessfullyCompletedLabel);
				}
			});
		};

		scope.clearPlatformCache = function() {
			var parameters = {};
        	parameters.methodName =  "clearPlatformCache";
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
        	remoteOptions.parameters =  JSON.stringify(parameters);
        	var toast = basicService.infoToast(labels.ClearManagedPlatformCache, labels.RunningLabel);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				toast.hide();
				if(result.hasErrors) {
					basicService.errorToast(labels.ClearManagedPlatformCache, result.errorMessage);
				} else {
					basicService.successToast(labels.ClearManagedPlatformCache, labels.SuccessfullyCompletedLabel);
				}
			});
		};

		scope.refreshPriceBook = function() {
			var parameters = {};
			parameters.methodName =  "refreshPriceBook";
			var remoteOptions ={};
			remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
			remoteOptions.parameters =  JSON.stringify(parameters);
			var toast = basicService.infoToast(labels.RefreshPricebook, labels.StartingLabel);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				scope.refreshPriceBookJobList = result.productAttributesBatchJobs;
				toast.hide();
				basicService.successToast(labels.RefreshPricebook, labels.RunningLabel);
			});
		};

		scope.importEpcObjectsLayouts = function() {
			var path = '/apex/'+scope.nsPrefix+'DataPacksHome?dataPackDataPublicId=DP_CPQ_EpcDefaultObjects&dataPackDataPublicSource=Vlocity%20Resource'
			window.open(path, '_blank');
		};

		scope.importPricingPlanData = function() {
			var path = '/apex/'+scope.nsPrefix+'DataPacksHome?dataPackDataPublicId=DP_CPQ_PricingPlanDefaultData&dataPackDataPublicSource=Vlocity%20Resource'
			window.open(path, '_blank');
		};

		scope.createEpcObjectClasses = function() {
			var parameters = {};
        	parameters.methodName =  "createEpcObjectClasses";
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
        	remoteOptions.parameters =  JSON.stringify(parameters);
        	var toast = basicService.infoToast(labels.CreateDefaultObjectClass, labels.RunningLabel);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				toast.hide();
				if(result.hasErrors) {
					basicService.errorToast(labels.CreateDefaultObjectClass, result.errorMessage);
				} else {
					basicService.successToast(labels.CreateDefaultObjectClass, labels.SuccessfullyCompletedLabel);
				}
			});
		};

		scope.createEpcDefaultLayouts = function() {
			var parameters = {};
        	parameters.methodName =  "createEpcDefaultLayouts";
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
        	remoteOptions.parameters =  JSON.stringify(parameters);
        	var toast = basicService.infoToast(labels.CreateDefaultLayout, labels.RunningLabel);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				toast.hide();
				if(result.hasErrors) {
					basicService.errorToast(labels.CreateDefaultLayout, result.errorMessage);
				} else {
					basicService.successToast(labels.CreateDefaultLayout, labels.SuccessfullyCompletedLabel);
				}
			});
		};

		scope.deleteEpcDefaultLayouts = function() {
			var parameters = {};
        	parameters.methodName =  "deleteEpcDefaultLayouts";
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
        	remoteOptions.parameters =  JSON.stringify(parameters);
        	var toast = basicService.infoToast(labels.DeleteDefaultObjectLayouts, labels.RunningLabel);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				toast.hide();
				if(result.hasErrors) {
					basicService.errorToast(labels.DeleteDefaultObjectLayouts, result.errorMessage);
				} else {
					basicService.successToast(labels.DeleteDefaultObjectLayouts, labels.SuccessfullyCompletedLabel);
				}
			});
		};

		scope.generateEPCGlobalKeys = function() {
			var parameters = {};
        	parameters.methodName = "generateEPCGlobalKeys";
            var remoteOptions ={};
            remoteOptions.apexType = scope.configData.telcoAdminConsoleClassType;
        	remoteOptions.parameters = JSON.stringify(parameters);
        	var toast = basicService.infoToast(labels.GenerateGlobalKey, labels.RunningLabel);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				toast.hide();
				if(result.hasErrors) {
					basicService.errorToast(labels.GenerateGlobalKey, result.errorMessage);
				} else {
					basicService.successToast(labels.GenerateGlobalKey, labels.SuccessfullyCompletedLabel);
				}
			});
		};

		scope.createDefaultPricingVariables = function() {
			var parameters = {};
        	parameters.methodName =  "createDefaultPricingVariables";
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
        	remoteOptions.parameters =  JSON.stringify(parameters);
        	var toast = basicService.infoToast(labels.CreateDefaultPVB, labels.RunningLabel);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				toast.hide();
				if(result.hasErrors) {
					basicService.errorToast(labels.CreateDefaultPVB, result.errorMessage);
				} else {
					basicService.successToast(labels.CreateDefaultPVB, labels.SuccessfullyCompletedLabel);
				}
			});
		};

		scope.createDefaultContextualAdjustmentData = function() {
			var parameters = {};
        	parameters.methodName =  "createDefContextualAdjData";
            var remoteOptions ={};

            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
        	remoteOptions.parameters =  JSON.stringify(parameters);
        	var toast = basicService.infoToast(labels.CreateContextualAdjustmentData, labels.RunningLabel);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				toast.hide();
				if(result.hasErrors) {
					basicService.errorToast(labels.CreateContextualAdjustmentData, result.errorMessage);
				} else {
					scope.hasErrors = false;
					basicService.successToast(labels.CreateContextualAdjustmentData, labels.SuccessfullyCompletedLabel);
				}
			});
		};

		scope.resetInterfaceImplementations = function() {
			var parameters = {};
        	parameters.methodName =  "resetInterfaceImplementations";
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
        	remoteOptions.parameters =  JSON.stringify(parameters);
        	var toast = basicService.infoToast(labels.InterfaceImplementationMaintenanceRestore, labels.RunningLabel);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				toast.hide();
				if(result.hasErrors) {
					basicService.errorToast(labels.InterfaceImplementationMaintenanceRestore, result.errorMessage);
				} else {
					basicService.successToast(labels.InterfaceImplementationMaintenanceRestore, labels.SuccessfullyCompletedLabel);
				}
			});
		};

		scope.mergeInterfaceImplementations = function() {
			var parameters = {};
        	parameters.methodName =  "mergeInterfaceImplementations";
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
        	remoteOptions.parameters =  JSON.stringify(parameters);
        	var toast = basicService.infoToast(labels.InterfaceImplementationMaintenanceMerge, labels.RunningLabel);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				toast.hide();
				if(result.hasErrors) {
					basicService.errorToast(labels.InterfaceImplementationMaintenanceMerge, result.errorMessage);
				} else {
					basicService.successToast(labels.InterfaceImplementationMaintenanceMerge, labels.SuccessfullyCompletedLabel);
				}
			});
		};


		scope.resetFieldMaps = function() {
			var parameters = {};
        	parameters.methodName =  "resetFieldMaps";
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
        	remoteOptions.parameters =  JSON.stringify(parameters);
        	var toast = basicService.infoToast(labels.FieldMapsMaintenance, labels.RunningLabel);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				toast.hide();
				if(result.hasErrors) {
					basicService.errorToast(labels.FieldMapsMaintenance, result.errorMessage);
				} else {
					basicService.successToast(labels.FieldMapsMaintenance, labels.SuccessfullyCompletedLabel);
				}
			});
		};

		scope.resetObjectMaps = function() {
			var parameters = {};
        	parameters.methodName =  "resetObjectMaps";
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
        	remoteOptions.parameters =  JSON.stringify(parameters);
            var toast = basicService.infoToast(labels.ObjectMapMaintenance, labels.RunningLabel);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				toast.hide();
				if(result.hasErrors) {
					basicService.errorToast(labels.ObjectMapMaintenance, result.errorMessage);
				} else {
					basicService.successToast(labels.ObjectMapMaintenance, labels.SuccessfullyCompletedLabel);
				}
			});
		};

		scope.refreshBatchJobLists = function() {
			var parameters = {};
        	parameters.methodName =  "refreshBatchJobLists";
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
        	remoteOptions.parameters =  JSON.stringify(parameters);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				scope.rootAccountJobsList = result.resolveRootAccountsJobs;
				scope.XLIBatchJobValidationList = result.xliBatchJobs;
				scope.attributesBindingJobsList = result.attributesBindingJobs;
				scope.rootProductChildItemJobsList = result.rootProductChildItemJobs;
				scope.productHierarchyJobsList = result.resolveProductHierarchyJobs;
				scope.refreshPriceBookJobList = result.productAttributesBatchJobs;
                scope.translationJobsList = result.translationJobs;
                scope.translationCacheJobsList = result.translationCacheJobs;
				//console.log(scope.XLIBatchJobValidationList);
				if(activeMenu.getActiveMenu() === 'MaintenanceJob.tpl.html' ||
					activeMenu.getActiveMenu() === 'UpgradeJob.tpl.html' ||
					activeMenu.getActiveMenu() === 'EPCJob.tpl.html' ||
                    activeMenu.getActiveMenu() === 'MLSJob.tpl.html') {
					timeout(scope.refreshBatchJobLists, 3000);
				}
			});
		};

		scope.refreshXLIBatchJobValidationLists = function() {
			var parameters = {};
        	parameters.methodName =  "refreshXLIBatchJobLists";
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
        	remoteOptions.parameters =  JSON.stringify(parameters);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				scope.XLIBatchJobValidationList = result.xliBatchJobValidationList;
				//debugger;
				//console.log(scope.XLIBatchJobValidationList);
				if(activeMenu.getActiveMenu() === 'MaintenanceJob.tpl.html' || activeMenu.getActiveMenu() === 'UpgradeJob.tpl.html') {
					timeout(scope.refreshXLIBatchJobValidationLists, 3000);
				}

			});
		};
		scope.startProductHierarchyJob = function() {
			var parameters = {};
        	parameters.methodName =  "startProductHierarchyJob";
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
        	remoteOptions.parameters =  JSON.stringify(parameters);
			var toast = basicService.infoToast(labels.ProductHierarchyMaintenanceTitle, labels.StartingLabel);
			remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
				scope.productHierarchyJobsList = result.resolveProductHierarchyJobs;
				toast.hide();
				basicService.successToast(labels.ProductHierarchyMaintenanceTitle, labels.RunningLabel);
			}, function(error) {
				toast.hide();
				basicService.errorToast(labels.ProductHierarchyMaintenanceTitle, labels.CouldntStartLabel);
			});
		};
        scope.loadDefaultObjectFieldsConfigMLS = function() {
            var parameters = {};
            parameters.methodName =  "loadDefaultObjectFieldsConfigMLS";
            var remoteOptions ={};
            remoteOptions.apexType =  scope.configData.telcoAdminConsoleClassType;
            remoteOptions.parameters =  JSON.stringify(parameters);
            var toast = basicService.infoToast(labels.LoadDefaultObjectFieldMLS, labels.RunningLabel);
            remoteActions.telcoAdminConsloleInvokeMethod(remoteOptions).then(function(result) {
                toast.hide();
                if(result.hasErrors) {
                    basicService.errorToast(labels.LoadDefaultObjectFieldMLS, result.errorMessage);
                } else {
                    basicService.successToast(labels.LoadDefaultObjectFieldMLS, labels.SuccessfullyCompletedLabel);
                }
            });
        };
		scope.addOrderLineItemJob = function() {
			scope.$parent.spinner.showSpinner();
			remoteActions.AddXLITime().then(function(result) {
				scope.$parent.spinner.hideSpinner();
				scope.result = result;
				if(result.hasErrors) {
					scope.errorMessage = result.errorMessage;
					scope.hasErrors = true;
				} else {
					scope.hasErrors = false;
				}
			}, function(error) {
				if(result.hasErrors) {
					scope.errorMessage = result.errorMessage;
					scope.hasErrors = true;
				} else {
					scope.hasErrors = false;
				}
			});
		};

		scope.testConfigurationsJob = function() {
			scope.$parent.spinner.showSpinner();
			remoteActions.testConfigurationsJob().then(function(result) {
				scope.$parent.spinner.hideSpinner();
				scope.configResult = result.mapResult;
				if(result.hasError) {
					scope.errorMessage = result.errorMessage;
					scope.hasError = true;
				} else {
					scope.hasError = false;
				}
			}, function(error) {
				if(result.hasError) {
					scope.errorMessage = result.errorMessage;
					scope.hasError = true;
				} else {
					scope.hasError = false;
				}
			});
		};
	}
]);

},{}],3:[function(require,module,exports){
var app = angular.module('CMTAdmin');
app.controller('CMTAdminController', ['$scope', '$sldsModal', 'BasicService', 'PageSpinner', 'ActiveMenu', 'remoteActions', '$window',
	function (scope, modal, basicService, spinner, activeMenu, remoteActions, window) {
		scope.SLDSICON = window.SLDSICON;
		scope.labels = window.labels;
		scope.nsPrefix = window.configData.nsPrefix;
		scope.configurations = [];
		scope.selectedConfigurationIndex = 0;
		scope.spinner = spinner;
		scope.sectionList = [];
		scope.activeMenu = activeMenu;
		scope.showClickedMenu = function(menu) {
			scope.activeMenu.setActiveMenu(menu);
		};
	}
]);

},{}],4:[function(require,module,exports){
var app = angular.module('CMTAdmin');
app.controller('CustomSettingsController', ['$scope', '$sldsModal', 'BasicService', 'remoteActions', '$window', 'fieldLookupService',
	function (scope, modal, basicService, remoteActions, window, fieldLookupService) {
		scope.SLDSICON = window.SLDSICON;
		scope.labels = window.labels;
		scope.subModuleList = [];
		scope.module = {};
		scope.activeTab = 0;
		scope.search = {'name': ''};
		scope.allObjectList = [];
		scope.booleanSelectionOptions = [{"value":true,"label":"Yes"},{"value":false,"label":"No"}];
		scope.nsPrefix = window.configData.nsPrefix;
		scope.isDuplicateSequence = false;
		scope.tab = {
			index: 0
		};

		scope.$watch('tab.index', function(newValue, oldValue) {
			//get records on tab changes
			scope.activeTab = newValue;
			scope.getCustomSettingsRecord();
		});
		scope.filterList = function(item) {
			if(scope.search.name === '') {
				return true;
			}
			var fields = [];
			fields.push(item[scope.nsPrefix + 'ObjectName__c']);
			fields.push(item[scope.nsPrefix + 'Object_Name__c']);
			fields.push(item[scope.nsPrefix + 'IsEditable__c']);
			fields.push(item[scope.nsPrefix + 'Popup_Page_Id__c']);
			fields.push(item[scope.nsPrefix + 'SetupValue__c']);
			fields.push(item[scope.nsPrefix + 'Value__c']);
			fields.push(item[scope.nsPrefix + 'Sequence__c']);
			fields.push(item[scope.nsPrefix + 'FieldName__c']);
			if(scope.subModuleList[scope.activeTab].name === 'configurations') {
				// add name field
				fields.push(item.Name);
			}

			return scope.find(fields);
		};
		scope.find = function(fields) {
			for(var i=0; i<fields.length; i++) {
				if(fields[i]) {
					var m = (fields[i] + '').toLowerCase().match(scope.search.name.toLowerCase());
					if(m && m.length > 0) {
						return true;
					}
				}
			}
			return false;
		};
		scope.verifyDuplicate = function(propertyName) {
	        var sorted, i;
	        var records = scope.subModuleList[scope.activeTab].records;
	        var isInvalid = false;
	        sorted = records.concat().sort(function (a, b) {
	            if (a[propertyName] > b[propertyName]) return 1;
	            if (a[propertyName] < b[propertyName]) return -1;
	            return 0;
	        });
	        for(i = 0; i < records.length; i++) {
	            sorted[i].isDuplicate = ((sorted[i-1] && sorted[i-1][propertyName] == sorted[i][propertyName]) || (sorted[i+1] && sorted[i+1][propertyName] == sorted[i][propertyName]));
	            if(sorted[i].isDuplicate && !isInvalid) {
	            	isInvalid = sorted[i].isDuplicate;
	            }
	        }
	        scope.isDuplicate = isInvalid;
	    };
		scope.getMetadata = function() {
			scope.spinner.showSpinner();
			remoteActions.getCustomSettingsMetadata(scope.module.name).then(function(results) {
		        if(results.hasError){
					basicService.openAlertWindow(scope.labels.CustomSettingsError, error);
					scope.$parent.spinner.hideSpinner();
				}else{
					var module = results.result[0];
					scope.module = module;
					scope.subModuleList = module.subModuleList;
					scope.getCustomSettingsRecord();
				}

			}, function(error) {
				scope.$parent.spinner.hideSpinner();
				basicService.openAlertWindow(scope.labels.CustomSettingsError, error);
			});
		};
		scope.getCustomSettingsRecord = function() {
			if(!scope.subModuleList[scope.activeTab]) {
				return ;
			}
			scope.$parent.spinner.showSpinner();
			var objectAPI = scope.subModuleList[scope.activeTab].objectAPI;
			var feature = scope.subModuleList[scope.activeTab].feature;
			remoteActions.getCustomSettingsRecord(objectAPI, feature).then(function(results) {
				if(results.hasError) {
					basicService.openAlertWindow(scope.labels.CustomSettingsError, results.errorMessage);
				} else {
					scope.subModuleList[scope.activeTab].records = results.result;
				}
				scope.$parent.spinner.hideSpinner();
			}, function(error) {
				scope.$parent.spinner.hideSpinner();
				basicService.openAlertWindow(scope.labels.CustomSettingsError, error);
			});
		};
		scope.initApp = function(name) {
			scope.module.name = name;
			scope.getMetadata();
			scope.getObjectList();
		};
		scope.getObjectList = function() {
			var parameters = {};
            parameters.methodName =  'getGlobalDescribe';
            var remoteOptions ={};
            remoteOptions.apexType =  window.configData.adminClassType;
            remoteOptions.parameters =  JSON.stringify(parameters);
			remoteActions.getObjectList(remoteOptions).then(function(result) {
				scope.allObjectList = JSON.parse(result.objectsDescribeListJSON.toString().replace('\n', ''));
			}, function(err) {
				basicService.openAlertWindow(scope.labels.CustomSettingsError, error);
			});
		};
		scope.delete = function(record, index) {
			var objectAPI = scope.subModuleList[scope.activeTab].objectAPI;
			var customsettingsID = record.Id;
			//var modalInstance = modal();
			var modalScope = scope.$new();
            modalScope.confirmationTitle = scope.labels.DeleteCustomSettingsLabel;
            modalScope.confirmationMsg = scope.labels.DeleteCustomSettingsWarningMessage;
            modalScope.cancelActionLbl = scope.labels.CancelLabel;
            modalScope.confirmActionLbl = scope.labels.DeleteLabel;
            modalScope.SLDSICON = scope.SLDSICON;
            modalScope.confirmAction = function() {
            	deleteModal.hide();
            	var records = scope.subModuleList[scope.activeTab].records;
                if(customsettingsID) {
                    scope.$parent.spinner.showSpinner();
					remoteActions.deleteCustomSettings(customsettingsID, objectAPI).then(function(results){
						scope.$parent.spinner.hideSpinner();
						if(results.hasError){
							basicService.openAlertWindow(scope.labels.CustomSettingsError, results.errorMessage);
						} else {
							records = records.splice(index, 1);
						}
	                }, function(error) {
	                	scope.$parent.spinner.hideSpinner();
	                    basicService.openAlertWindow(scope.labels.CustomSettingsError, error);
	                });
				} else {
					records = records.splice(index, 1);
				}
            };
			var deleteModal = modal({
                templateUrl: 'ConfirmationModal.tpl.html',
                backdrop: 'static',
                scope: modalScope,
                show: true
			});
		};
		scope.checkSaveMode = function() {
			var save = false;
			var records = scope.subModuleList[scope.activeTab].records;
			if(records) {
				for(var i=0; i<records.length; i++) {
					if(records[i].editMode) {
						save = true;
						break;
					}
				}
			}
			return !save;
		};
		scope.add = function(records) {
			if(!records){
				records = [];
			}
			records.push(scope.createEmptyRecord());
		};
		scope.createEmptyRecord = function() {
			var record = {};
			var metaDataList = scope.subModuleList[scope.activeTab].metaDataList;
			for(var i=0; i<metaDataList.length; i++) {
				record[metaDataList[i].name] = '';
			}
			record.editMode = true;
			return record;
		};
		scope.fixLookupRecordBeforeSave = function(records) {
			for(var i=0; i<records.length; i++) {
				delete records[i].isDuplicate;
				delete records[i].editMode;
			}
		};
		scope.fixConfigRecordBeforeSave = function(records) {
			for(var i=0; i<records.length; i++) {
				delete records[i].isDuplicate;
				delete records[i].editMode;
			}
		};
		scope.fixFieldRecordBeforeSave = function(records) {
			for(var i=0; i<records.length; i++) {
				var sequence = records[i][scope.nsPrefix + 'Sequence__c'];
				if(!sequence) {
					records[i][scope.nsPrefix + 'Sequence__c'] = 0;
				}
				var feature = scope.subModuleList[scope.activeTab].feature;
				records[i][scope.nsPrefix + 'Feature__c'] = feature;
				delete records[i].isDuplicate;
				delete records[i].editMode;
			}
		};
		scope.save = function() {
			scope.$parent.spinner.showSpinner();
			var objectAPI = scope.subModuleList[scope.activeTab].objectAPI;
			var records = [];
			//get only edited records
			for(var i=0; i<scope.subModuleList[scope.activeTab].records.length; i++) {
				var record = scope.subModuleList[scope.activeTab].records[i];
				if(record.editMode) {
					records.push(record);
				}
			}
			var name = scope.subModuleList[scope.activeTab].name;
			if(name === 'displayFields' || name === 'queryFields' || name === 'updateFields') {
				scope.fixFieldRecordBeforeSave(records);
			} else if(name === 'lookupFields') {
				scope.fixLookupRecordBeforeSave(records);
			} else if(name === 'configurations') {
				scope.fixConfigRecordBeforeSave(records);
			}
			remoteActions.saveCustomSettings(objectAPI, angular.toJson(records)).then(function(results) {
				if(results.hasError){
					scope.$parent.spinner.hideSpinner();
					basicService.openAlertWindow(scope.labels.CustomSettingsError, results.errorMessage);
				} else{
					//saved
					scope.getCustomSettingsRecord();
				}
			}, function(error) {
				scope.$parent.spinner.hideSpinner();
				basicService.openAlertWindow(scope.labels.CustomSettingsError, error);
			});
		};
		scope.convertFieldSelName = function(fieldName) {
			var cFields = [];
			var names = fieldName.split(".");
			if(names.length > 1) {
				for(var i=0; i<names.length; i++) {
					if(names[i].indexOf('__c') !== -1 && i < names.length - 1){
						cFields.push(names[i].replace('__c','__r'));
					} else if (i < names.length - 1){
						cFields.push(names[i].substring(0, names[i].length-2));
					} else{
						cFields.push(names[i]);
					}
				}
			} else {
				cFields.push(fieldName);
			}
			return cFields.join(".");
		};
		scope.openFieldSelection = function (record) {
			var modalScope = scope.$new();
            modalScope.confirmationTitle = scope.labels.FieldSelectionLabel;
            modalScope.cancelActionLbl = scope.labels.CancelLabel;
            modalScope.confirmActionLbl = scope.labels.SaveLabel;
            modalScope.objectName = record[scope.nsPrefix + 'ObjectName__c'] || record[scope.nsPrefix + 'Object_Name__c'];
            modalScope.fieldName = scope.convertFieldSelName(record[scope.nsPrefix + 'FieldName__c']);
            modalScope.selectedFields = [];
            modalScope.nsPrefix = scope.nsPrefix;
            modalScope.SLDSICON = scope.SLDSICON;
            modalScope.confirmAction = function() {
                //
                var fieldInfo = scope.parseFields(modalScope.selectedFields);
                record.fieldName = fieldInfo.label;
                record[scope.nsPrefix + 'FieldName__c'] = fieldInfo.apiName;
                fieldSelectionModal.hide();
            };
			var fieldSelectionModal = modal({
				templateUrl: 'FieldSelectionModal.tpl.html',
                backdrop: 'static',
                scope: modalScope,
                show: true
			});
		};
		scope.parseFields = function(selectedFields) {
			var fieldName = [];
			var fieldApiNames = [];
			var fieldType = null;
			var numberOfFields = selectedFields.length;
			var lastReferenceObject = null;
			for (i = 0; i < numberOfFields; i++) {
				var fieldInfo = selectedFields[i];
				if(fieldInfo.type === 'reference'){
					lastReferenceObject = fieldInfo.referenceTo[0];
				}
				// if it's a reference field and there is an element after it
				if(fieldInfo.type === 'reference' && i < numberOfFields - 1){
					if(fieldInfo.name.indexOf('__c') !== -1){
						fieldName.push(fieldInfo.name.replace('__c','__r'));

					}else{
						fieldName.push(fieldInfo.name.substring(0,fieldInfo.name.length-2));

					}
				} else {
					fieldName.push(fieldInfo.name);

				}
				fieldType = fieldInfo.type;
				fieldApiNames.push(fieldInfo.name);
			}
			var fullFieldName = '';
			for (i = 0; i < fieldName.length; i++) {
				fullFieldName += fieldName[i];
				if(i !==  fieldName.length-1){
					fullFieldName += '.';
				}

			}
			retVal = {};
			retVal.fullFieldName = fullFieldName;
			retVal.fieldType = fieldType;
			retVal.lastReferenceObject = lastReferenceObject;
			if(fieldApiNames.length > 0) {
				retVal.apiName = fieldApiNames.join(".");
			}
			return retVal;
		};
		scope.openPageSelection = function(record) {
			var modalScope = scope.$new();
            modalScope.confirmationTitle = scope.labels.PageSelectionLabel;
            modalScope.cancelActionLbl = scope.labels.CancelLabel;
            modalScope.confirmActionLbl = scope.labels.SaveLabel;
            modalScope.pageWrapper = {page:{}};
            modalScope.pageWrapper.page.Name = record[scope.nsPrefix + 'Popup_Page_Id__c'];
            modalScope.nsPrefix = scope.nsPrefix;
            modalScope.SLDSICON = scope.SLDSICON;
            scope.$parent.spinner.hideSpinner();
            modalScope.search = '';
            modalScope.confirmAction = function() {
                record[scope.nsPrefix + 'Popup_Page_Id__c'] = modalScope.pageWrapper.page.Name;
                pageSelectionModal.hide();
            };
            modalScope.init = function() {
            	modalScope.getPageList('');
            };
            modalScope.searchPage = function(search) {
            	modalScope.getPageList(search);
            };
            modalScope.getPageList = function(search) {
            	scope.$parent.spinner.showSpinner();
            	remoteActions.getPageList(search).then(function(results) {
					if(results.hasError){
						basicService.openAlertWindow(scope.labels.CustomSettingsError, results.errorMessage);
					} else{
						//saved
						modalScope.pageList = results.result;
					}
					scope.$parent.spinner.hideSpinner();
				}, function(error) {
					scope.$parent.spinner.hideSpinner();
					basicService.openAlertWindow(scope.labels.CustomSettingsError, error);
				});
            };
			var pageSelectionModal = modal({
				templateUrl: 'PageSelectionModal.tpl.html',
                backdrop: 'static',
                scope: modalScope,
                show: true
			});
			modalScope.init();
		};
	}
]);

},{}],5:[function(require,module,exports){
var app = angular.module('CMTAdmin');
app.controller('DashboardController', ['$scope', '$sldsModal', 'BasicService', 'PageSpinner', 'ActiveMenu', 'remoteActions', '$window',
	function (scope, modal, basicService, spinner, activeMenu, remoteActions, window) {
		scope.SLDSICON = window.SLDSICON;
		scope.labels = window.labels;
		scope.nsPrefix = window.configData.nsPrefix;
		scope.configurations = [];
		scope.selectedConfigurationIndex = 0;
		scope.spinner = spinner;
		scope.sectionList = [];

		scope.initApp = function() {
			scope.spinner.showSpinner();
			remoteActions.getAdminOptions().then(function(results) {
		        if(results.hasError) {
					basicService.openAlertWindow(scope.labels.CMTAdminError, error);
				}else{
					scope.sectionList = results.result;
				}
				scope.spinner.hideSpinner();
			}, function(error) {
				scope.spinner.hideSpinner();
				basicService.openAlertWindow(scope.labels.CMTAdminError, error);
			});
		};

		scope.showClickedMenu = function(menu) {
			activeMenu.setActiveMenu(menu);
		};
	}
]);

},{}],6:[function(require,module,exports){
var app = angular.module('CMTAdmin');
app.controller('EnableFeaturesController', ['$scope', '$sldsModal', 'BasicService', 'remoteActions', '$window',
    function (scope, modal, basicService, remoteActions, window) {
        scope.SLDSICON = window.SLDSICON;
        scope.labels = window.labels;
        scope.nsPrefix = window.configData.nsPrefix;
        scope.loyaltyPoints = {};
        scope.featureList;
        scope.module = {};

        scope.initApp = function(name, label) {
            scope.module.name = name;
            scope.module.label = label;
            scope.getMetadata();
        };
        scope.getMetadata = function() {
            scope.$parent.spinner.showSpinner();
            remoteActions.getCustomSettingsMetadata(scope.module.name).then(function(results) {
                if(results.hasError){
                    basicService.openAlertWindow(scope.labels.EnableFeatureError, error);
                    scope.$parent.spinner.hideSpinner();
                }else{
                    var module = results.result[0];
                    scope.module = module;
                    scope.subModule = module.subModuleList[0];
                    scope.getCustomSettingsRecord();
                }
            }, function(error) {
                basicService.openAlertWindow(scope.labels.EnableFeatureError, error);
                scope.$parent.spinner.hideSpinner();
            });
        };
        scope.getCustomSettingsRecord = function() {
            var objectAPI = scope.subModule.objectAPI;
            var feature = scope.subModule.feature;
            remoteActions.getCustomSettingsRecord(objectAPI, feature).then(function(results) {
                if(results.hasError) {
                    basicService.openAlertWindow(scope.labels.EnableFeatureError, results.errorMessage);
                } else {
                    scope.featureList = results.result;
                }
                scope.$parent.spinner.hideSpinner();
            }, function(error) {
                scope.$parent.spinner.hideSpinner();
                basicService.openAlertWindow(scope.labels.EnableFeatureError, error);
            });
        };
        scope.enableDisableFeature = function(f) {
            var feature = angular.copy(f);
            var modalScope = scope.$new();
            if(feature.isEnabled) {
                modalScope.confirmActionLbl = scope.labels.Enable;
                modalScope.confirmationMsg = scope.labels.EnableSettingWarning;
                modalScope.confirmationTitle = scope.labels.Enable+ ' '+ feature.label;
            } else {
                modalScope.confirmActionLbl = scope.labels.Disable;
                if(feature.warningMessage){
                    modalScope.confirmationMsg = feature.warningMessage;
                } else {
                    modalScope.confirmationMsg = 'Are you sure want to disable this setting?';
                }
                modalScope.confirmationClass = 'slds-theme_warning';
                modalScope.confirmationTitle = scope.labels.Disable + ' ' + feature.label;
            }
            modalScope.cancelActionLbl = scope.labels.CancelLabel;
            modalScope.isCancelActionRequried = true;
            modalScope.SLDSICON = scope.SLDSICON;
            modalScope.cancelAction = function() {
                f.isEnabled = !f.isEnabled;
                confirmModal.hide();
            };
            modalScope.confirmAction = function() {
                feature[scope.nsPrefix + 'SetupValue__c'] = feature.isEnabled + '';
                delete feature['label'];
                delete feature['warningMessage'];
                delete feature['isEnabled'];
                var objectAPI = scope.subModule.objectAPI;
                confirmModal.hide();
                scope.$parent.spinner.showSpinner();
                remoteActions.saveCustomSettings(objectAPI, angular.toJson(feature)).then(function(results) {
                    if(results.hasError){
                        basicService.openAlertWindow(scope.labels.EnableFeatureError, results.errorMessage);
                    } else {
                        if(f.isEnabled) {
                            basicService.openSuccessWindow(f.label, scope.labels.EnableFeatureSuccessMessage);
                        } else {
                            basicService.openSuccessWindow(f.label, scope.labels.DisableFeatureSuccessMessage);
                        }
                    }
                    scope.$parent.spinner.hideSpinner();
                }, function(error) {
                    scope.$parent.spinner.hideSpinner();
                    basicService.openAlertWindow(scope.labels.EnableFeatureError, error);
                });
            };
            var confirmModal = modal({
                templateUrl: 'ConfirmationModal.tpl.html',
                backdrop: 'static',
                scope: modalScope,
                show: true
            });
        }
    }
]);

},{}],7:[function(require,module,exports){
angular.module('CMTAdmin')
.factory('PageSpinner', [
	function(){
		var spinner = false;
		return {
			getSpinner: function() {
				return spinner;
			},
			showSpinner: function() {
				spinner = true;
			},
			hideSpinner: function() {
				spinner = false;
			}
		};
	}
]);
angular.module('CMTAdmin')
.factory('ActiveMenu', [
	function(){
		var menuTemplate = 'Dashboard.tpl.html';
		return {
			getActiveMenu: function() {
				return menuTemplate;
			},
			setActiveMenu: function(menu) {
				menuTemplate = menu + '.tpl.html';
			}
		};
	}
]);
// This module is necessary to pass salesforce merged valued to directives in static resources.
//used for the field Lookup Directive
angular.module('parameters',[])
	.factory('ParametersFactory', ['$window', function(window){
		var factory = {};
		factory.getRemoteInvokeMethod = function(){
			return window.configData.adminInvokeMethod;
		
		};
		
		factory.getClassType = function(){
			return window.configData.adminClassType;
		
		};
		
		factory.getLoadingImg = function(){
			return window.configData.waitingImage;
		};
		
		factory.getNsPrefix = function(){
			return window.configData.nsPrefix;
		};
		
		return factory;
	
	}]);
},{}],8:[function(require,module,exports){
var app = angular.module('CMTAdmin');
app.service('BasicService',['$sldsModal', '$sldsToast', '$sldsPrompt', '$window', function BasicService(modal, toast, prompt, window) {

    BasicService.prototype.openAlertWindow = function (title, message) {
        deletePrompt = prompt({
            title: title,
            content: message,
            theme: 'error',
            show: true,
            buttons: [{
                label: window.labels.OKLabel,
                type: 'neutral',
                action: function() {
                    deletePrompt.hide();
                }
            }]
        });
	};

    BasicService.prototype.openSuccessWindow = function (title, message) {
        deletePrompt = prompt({
            title: title,
            content: message,
            theme: 'success',
            show: true,
            buttons: [{
                label: window.labels.OKLabel,
                type: 'neutral',
                action: function() {
                    deletePrompt.hide();
                }
            }]
        });
    };

    BasicService.prototype.successToast = function (title, content) {
        return toast({
            title: title,
            content: content,
            severity: 'success',
            icon: 'success',
            templateUrl: 'SldsToast.tpl.html',
            autohide: true,
            show: true
        });
    };

    BasicService.prototype.errorToast = function (title, content) {
        return toast({
            title: title,
            content: content,
            severity: 'error',
            icon: 'error',
            templateUrl: 'SldsToast.tpl.html',
            autohide: false,
            show: true
        });
    };

    BasicService.prototype.warningToast = function (title, content) {
        return toast({
            title: title,
            content: content,
            severity: 'warning',
            icon: 'warning',
            templateUrl: 'SldsToast.tpl.html',
            autohide: false,
            show: true
        });
    };

    BasicService.prototype.infoToast = function (title, content) {
        return toast({
            title: title,
            content: content,
            severity: 'info',
            icon: 'info',
            templateUrl: 'SldsToast.tpl.html',
            autohide: false,
            show: true
        });
    };
}]);

},{}],9:[function(require,module,exports){
angular.module("CMTAdmin").run(["$templateCache",function($templateCache){"use strict";$templateCache.put("ConfirmationModal.tpl.html",'<section role="dialog" tabindex="-1" aria-labelledby="modal-heading-01" aria-modal="true" aria-describedby="modal-content-id-1" class="slds-modal slds-fade-in-open">\n    <div class="slds-modal__container">\n        <div class="slds-modal__header" ng-class="confirmationClass">\n            <slds-button-svg-icon sprite="\'utility\'" icon="\'close\'" size="\'large\'" extra-classes="\'slds-modal__close slds-button_icon-inverse\'" ng-click="isCancelActionRequried ? cancelAction() : $hide()"></slds-button-svg-icon>\n            <h2 class="slds-text-heading_medium slds-hyphenate">{{confirmationTitle}}</h2>\n        </div>\n        <div class="slds-modal__content slds-p-around_medium">\n            <div>\n                <p ng-bind-html="confirmationMsg"></p>\n            </div>\n        </div>\n        <div class="slds-modal__footer">\n            <button type="button" class="slds-button slds-button_neutral" ng-click="isCancelActionRequried ? cancelAction() : $hide()">{{cancelActionLbl}}</button>\n            <button type="button" class="slds-button slds-button_brand" ng-click="confirmAction()">{{confirmActionLbl}}</button>\n        </div>\n    </div>\n</section>\n<div class="slds-backdrop slds-backdrop_open"></div>\n'),$templateCache.put("CpqConfig.tpl.html",'<div ng-controller="CustomSettingsController" ng-init="initApp(\'genericcpq\')">\n\t<div ng-include="\'SubHeader.tpl.html\'"></div>\n\t<div class="slds-p-around_small" slds-active-pane="tab.index" slds-tabs-pane-class="slds-p-top_none" slds-tabs="true">\n\t\t<div ng-repeat="subModule in subModuleList" slds-pane="true" data-title="{{subModule.label}}" ng-include="\'Module.tpl.html\'"></div>\n\t</div>\n</div>'),$templateCache.put("CustomSettings.tpl.html",'<div ng-controller="CustomSettingsController" class="grid-wrapper slds-grid slds-theme_shade" ng-init="initApp()">\n\t<div class="module-menu slds-grid_vertical slds-size_3-of-12 slds-p-left-medium">\n\t\t<ul role="menu" class="slds-has-block-links_space slds-has-dividers_bottom">\n\t\t\t<li ng-repeat="module in metadata track by $index" class="slds-item slds-clearfix" ng-class="activeIndex.module === $index ? \'slds-item-active\': \'\'" ng-click="makeActiveModule($index)">\n\t\t\t\t<a role="menuitem" href="javascript:void(0);" >\n\t                <p class="slds-truncate" ng-click="menuToggle = module">\n\t                  <span class="slds-icon_container slds-m-right_medium slds-float_right">\n\t                    <svg aria-hidden="true" class="slds-icon slds-icon-text-default slds-icon_x-small">\n\t                      <use xlink:href="{{SLDSICON.RIGHT_ARROW}}"></use>\n\t                    </svg>\n\t                  </span>\n\t                  <span>{{module.label}}</span>\n\t                </p>\n\t            </a>\n\t\t\t</li>\n\t\t</ul>\n\t</div>\n\t<div class="tab-wrapper slds-grid_vertical slds-size_9-of-12 slds-p-left_medium slds-p-right_x-small">\n\t\t<div slds-active-pane="activeIndex.subModule" slds-tabs-pane-class="slds-p-top_none" slds-tabs="true">\n\t\t\t<div ng-repeat="subModule in metadata[activeIndex.module].subModuleList" slds-pane="true" data-title="{{subModule.label}}" ng-include="\'Module.tpl.html\'"></div>\n\t\t</div>\n\t</div>\n</div>'),$templateCache.put("Dashboard.tpl.html",'<div ng-controller="DashboardController" ng-init="initApp()">\n    <div class="slds-p-around_small">\n    </div>\n    <div class="slds-grid slds-grid_pull-padded-small">\n    \t<div class="slds-p-horizontal_small slds-size_1-of-3 slds-medium-size_2-of-6 slds-large-size_4-of-12" ng-repeat="section in sectionList track by $index" ng-class="{\'slds-p-right_small\': $index % 1 === 0}">\n            <div class="slds-card">\n                <div class="slds-card__header slds-grid grid_flex-spread slds-p-horizontal_x-small">\n                    <h2 class="slds-text-heading_medium slds-truncate" title="{{section.name}}">{{section.label}}</h2>\n                </div>\n                <div class="slds-card__body">\n                    <ul class="slds-list_vertical slds-has-dividers_top-space slds-has-list-interactions slds-theme_default fix-border-bottom-radius">\n                        <li class="slds-list__item slds-p-horizontal_x-small" ng-repeat="menu in section.menuList">\n                            <div class="slds-clearfix">\n                                <div class="slds-float_left">\n                                    <a href ng-click="showClickedMenu(menu.name)" title="{{menu.label}}">{{menu.label}}\n                                    </a>\n                                </div>\n                            </div>\n                        </li>\n                    </ul>\n                </div>\n            </div>\n        </div>\n    </div>\n</div>\n'),$templateCache.put("EPCJob.tpl.html",'<div ng-controller="AdminConsoleController" ng-init="initApp(\'epcJobs\', labels.CMTOptionEPCJobsLabel)">\n\t<div ng-include="\'SubHeader.tpl.html\'"></div>\n\t<div class="job-wrapper">\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom">\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)">{{labels.InstallDefaultLayouts}}</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_x-small">{{labels.InstallDefaultLayoutsDesc}}</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button type="button" ng-click="importEpcObjectsLayouts();" class="slds-button  slds-button_brand">{{labels.InstallLabel}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t</div>\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom">\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)">{{labels.InstallDefaultPPD}}</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_x-small">{{labels.InstallDefaultPPDDesc}}</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button type="button" ng-click="importPricingPlanData();" class="slds-button  slds-button_brand">{{labels.InstallLabel}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t</div>\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom">\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)">{{labels.DeleteDefaultObjectLayouts}}</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_x-small">{{labels.DeleteLayoutsDesc}}</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button type="button" ng-click="deleteEpcDefaultLayouts();" class="slds-button  slds-button_brand">{{labels.StartDT}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t</div>\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom">\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)">{{labels.CreateDefaultPVB}}</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_x-small">{{labels.CreateDefaultPVBDesc}}</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button type="button" ng-click="createDefaultPricingVariables();" class="slds-button  slds-button_brand">{{labels.StartDT}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t</div>\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom">\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)">Create Default Contextual Adjustment Data</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_x-small">Creates default contextual adjustment data</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button id="createDefaultContextualAdjustmentDataButton" type="button" ng-click="createDefaultContextualAdjustmentData();" class="slds-button  slds-button_brand">{{labels.StartDT}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t\t<div class="row">\n\t\t\t\t<div id="createDefaultContextualAdjustmentDataStatus" class="col-md-12 col-sm-12 col-xs-12">\n\t\t\t\t\t<div ng-if="hasErrors" class="alert alert-danger" role="alert">{{errorMessage}}</div>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t</div>\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom">\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)">{{labels.GenerateGlobalKey}}</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_x-small">{{labels.GenerateGlobalKeyDesc}}</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button type="button" ng-click="generateEPCGlobalKeys();" class="slds-button  slds-button_brand">{{labels.StartDT}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t</div>\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom">\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)"><span class="slds-text-color_error">[{{labels.DeprecatedLabel}}]</span> {{labels.CreateDefaultObjectClass}}</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_x-small">{{labels.CreateDefaultObjectClassDesc}}</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button type="button" ng-click="createEpcObjectClasses();" class="slds-button  slds-button_brand">{{labels.StartDT}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t</div>\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom">\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)"><span class="slds-text-color_error">[{{labels.DeprecatedLabel}}]</span> {{labels.CreateDefaultLayout}}</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_x-small">{{labels.CreateDefaultLayoutDesc}}</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button type="button" ng-click="createEpcDefaultLayouts();" class="slds-button  slds-button_brand">{{labels.StartDT}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t</div>\n\t</div>\n</div>\n'),$templateCache.put("EnableFeatures.tpl.html",'<div ng-controller="EnableFeaturesController" ng-init="initApp(\'EnableFeatures\', \'Enable Features\')">\n    <div ng-include="\'SubHeader.tpl.html\'"></div>\n    <div class="slds-theme_shade">\n        <div class="job-wrapper slds-p-around_medium" ng-repeat="feature in featureList">\n            <div class="slds-grid slds-theme_default slds-p-around_small">\n                <div class="slds-size_1-of-2 slds-p-top_x-small">\n                    <span ng-bind="feature.label"></span>\n                </div>\n                <div class="slds-size_1-of-2">\n                    <div class="slds-float_right slds-form-element">\n                        <label class="slds-checkbox_toggle slds-grid">\n                            <input type="checkbox" name="checkbox" aria-describedby="toggle-desc" ng-model="feature.isEnabled"\n                            ng-change="enableDisableFeature(feature)" />\n                            <span id="toggle-desc" class="slds-checkbox_faux_container" aria-live="assertive">\n                                <span class="slds-checkbox_faux"></span>\n                                <span class="slds-checkbox_on">{{labels.EnabledLabel}}</span>\n                                <span class="slds-checkbox_off">{{labels.DisabledLabel}}</span>\n                            </span>\n                        </label>\n                    </div>\n                </div>\n            </div>\n        </div>\n    </div>\n</div>\n'),$templateCache.put("ErrorModal.tpl.html",'<div>\n    <div aria-hidden="false" aria-labelledby="prompt-heading-id" aria-describedby="prompt-message-wrapper" role="alertdialog" class="slds-modal slds-modal_prompt slds-fade-in-open">\n        <div class="slds-modal__container slds-modal_prompt" role="document" id="prompt-message-wrapper" tabindex="0">\n            <div class="slds-modal__header slds-theme_alert-texture" ng-class="theme">\n                <h2 class="slds-text-heading_medium" id="prompt-heading-id">{{confirmationTitle}}</h2>\n            </div>\n            <div class="slds-modal__content slds-p-around_medium">\n                <div>\n                    <p>{{errorMessage}}</p>\n                </div>\n            </div>\n            <div class="slds-modal__footer slds-theme_default">\n                <button class="slds-button slds-button_neutral" ng-click="$hide()">{{cancelActionLbl}}</button>\n            </div>\n        </div>\n    </div>\n    <div class="slds-backdrop slds-backdrop_open"></div>\n</div>\n'),$templateCache.put("FieldSelectionModal.tpl.html",'<div class="slds-modal slds-fade-in-open" aria-hidden="false" role="dialog">\n    <div class="slds-modal__container">\n        <div class="slds-modal__header">\n            <button class="slds-button slds-button_icon-inverse slds-modal__close" ng-click="$hide()">\n                <svg aria-hidden="true" class="slds-button__icon slds-button__icon_large">\n                    <use xlink:href="{{SLDSICON.CLOSE}}"></use>\n                </svg>\n                <span class="slds-assistive-text">{{labels.CloseLabel}}</span>\n            </button>\n            <h2 class="slds-text-heading_medium">{{confirmationTitle}}</h2>\n        </div>\n        <div class="slds-modal__content slds-p-around_medium">\n            <field-Lookup object-name="objectName" field-name="fieldName" selected-fields="selectedFields"> </field-Lookup>\n        </div>\n        <div class="slds-modal__footer">\n            <button type="button" class="slds-button slds-button_neutral" ng-click="$hide()">{{cancelActionLbl}}</button>\n            <button type="button" class="slds-button slds-button_neutral slds-button_brand" ng-click="confirmAction()">{{confirmActionLbl}}</button>\n        </div>\n    </div>\n</div>\n<div class="slds-backdrop slds-backdrop_open"></div>\n'),$templateCache.put("FunctionalJob.tpl.html",'<div ng-controller="AdminConsoleController" ng-init="initApp(\'FunctionalJobs\', labels.CMTOptionFunctionalJobsLabel)">\n\t<div ng-include="\'SubHeader.tpl.html\'"></div>\n\t<div class="job-wrapper">\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom">\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)">{{labels.BasicConfigLabel}}</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_x-small">{{labels.BasicConfigDesc}}</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button id="testConfigurationsJobButton" type="button" ng-click="showTestResults = true; testConfigurationsJob();" class="slds-button  slds-button_brand">{{labels.CheckLabel}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\n\t\t\t<div class="row">\n\t\t\t\t<div id="testConfigurationsJobStatus" class="col-md-12 col-sm-12 col-xs-12">\n\t\t\t\t\t<div ng-if="hasError" style="color : red" class="alert alert-danger" role="alert">{{errorMessage}}</div>\n\t\t\t\t</div>\n\t\t\t</div>\n\n\t\t\t<div ng-if="configResult.Cache != 0" ng-show="showTestResults">\n\t\t\t\t<table class="slds-table slds-m-top_small slds-no-row-hover slds-table_fixed-layout">\n\t\t\t\t\t<tr ng-class="slds-theme_shade" style="background-color : #cfeef8">\n\t\t\t\t\t\t<th class="slds-cell-wrap" style="font-weight:900">Cache</th>\n\t\t\t\t\t\t<th class="slds-cell-wrap" style="font-weight:900">Current Status (Used Capacity)</th>\n\t\t\t\t\t\t<th class="slds-cell-wrap" style="font-weight:900">Expected Status</th>\n\t\t\t\t\t</tr>\n\t\t\t\t\t<tr ng-class="{\'slds-theme_error\': configResult.Cache.SessionCache !== \'Available\' || configResult.Cache.SessionCacheSize> 95}">\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>Session Cache</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>{{configResult.Cache.SessionCache}} ({{configResult.Cache.SessionCacheSize}}%)</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>Available</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t</tr>\n\t\t\t\t\t<tr ng-class="{\'slds-theme_error\': configResult.Cache.OrganizationCache !== \'Available\' || configResult.Cache.OrganizationCacheSize> 95}">\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>Organization Cache</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>{{configResult.Cache.OrganizationCache}} ({{configResult.Cache.OrganizationCacheSize}}%)</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>Available</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t</tr>\n\t\t\t\t</table>\n\t\t\t</div>\n\n\t\t\t<div ng-if="result != 0" ng-show="showTestResults">\n\t\t\t\t<table class="slds-table slds-m-top_small slds-no-row-hover slds-table_fixed-layout">\n\t\t\t\t\t<tr ng-class="slds-theme_success" style="background-color : #cfeef8">\n\t\t\t\t\t\t<th class="slds-cell-wrap" style="font-weight:900">Triggers</th>\n\t\t\t\t\t\t<th class="slds-cell-wrap" style="font-weight:900">Current Value</th>\n\t\t\t\t\t\t<th class="slds-cell-wrap" style="font-weight:900">Expected Value</th>\n\t\t\t\t\t</tr>\n\t\t\t\t\t<tr ng-class="{\n\t\t\t\t\t\t\t\t\t\'slds-theme_error\': configResult.AllTriggers != \'On\'\n\t\t\t\t\t\t\t\t\t}">\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>AllTriggers</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>{{configResult.AllTriggers}}</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>On</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t</tr>\n\t\t\t\t</table>\n\t\t\t</div>\n\n\t\t\t<div ng-if="result != 0" ng-show="showTestResults">\n\t\t\t\t<table class="slds-table slds-m-top_small slds-no-row-hover slds-table_fixed-layout">\n\t\t\t\t\t<tr ng-class="slds-theme_success" style="background-color : #cfeef8">\n\t\t\t\t\t\t<th class="slds-cell-wrap" style="font-weight:900">Custom Field Map</th>\n\t\t\t\t\t\t<th class="slds-cell-wrap" style="font-weight:900">Current Value</th>\n\t\t\t\t\t\t<th class="slds-cell-wrap" style="font-weight:900">Expected Value</th>\n\t\t\t\t\t</tr>\n\t\t\t\t\t<tr ng-class="{\'slds-theme_warning\': configResult.CustomFieldMapCount < 300}">\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>CustomFieldMapCount</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>{{configResult.CustomFieldMapCount}}</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>> 300</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t</tr>\n\t\t\t\t</table>\n\t\t\t</div>\n\n\t\t\t<div ng-if="result != 0" ng-show="showTestResults">\n\t\t\t\t<table class="slds-table slds-m-top_small slds-no-row-hover slds-table_fixed-layout">\n\t\t\t\t\t<tr ng-class="slds-theme_success" style="background-color : #cfeef8">\n\t\t\t\t\t\t<th class="slds-cell-wrap" style="font-weight:900">Interface Implementation</th>\n\t\t\t\t\t\t<th class="slds-cell-wrap" style="font-weight:900">Current Value</th>\n\t\t\t\t\t\t<th class="slds-cell-wrap" style="font-weight:900">Expected Value</th>\n\t\t\t\t\t</tr>\n\t\t\t\t\t<tr ng-class="{\'slds-theme_warning\': configResult.InterfaceImplementationCount < 50}">\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>InterfaceImplementationCount</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>{{configResult.InterfaceImplementationCount}}</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>>=50</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t</tr>\n\t\t\t\t</table>\n\t\t\t</div>\n\n\t\t\t<div ng-if="result != 0" ng-show="showTestResults">\n\t\t\t\t<table class="slds-table slds-m-top_small slds-no-row-hover slds-table_fixed-layout">\n\t\t\t\t\t<tr ng-class="slds-theme_success" style="background-color : #cfeef8">\n\t\t\t\t\t\t<th class="slds-cell-wrap" style="font-weight:900">Custom Settings</th>\n\t\t\t\t\t\t<th class="slds-cell-wrap" style="font-weight:900">Current Value</th>\n\t\t\t\t\t\t<th class="slds-cell-wrap" style="font-weight:900">Recommended Value</th>\n\t\t\t\t\t</tr>\n\t\t\t\t\t<tr ng-repeat="(key, value) in configResult.CustomSettings" ng-class="{\'slds-theme_error\': ((value.Current | lowercase) !== (value.Recommended | lowercase) && value.Recommended !== undefined)}">\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>{{key}}</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>{{value.Current}}</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>{{value.Recommended}}</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t</tr>\n\t\t\t\t</table>\n\t\t\t</div>\n\t\t</div>\n\t</div>\n</div>\n'),$templateCache.put("MLSFieldConfig.tpl.html",'<div ng-controller="CustomSettingsController" ng-init="initApp(\'mlsfieldconfig\')">\n    <div ng-include="\'SubHeader.tpl.html\'"></div>\n    <div class="slds-p-around_small" slds-active-pane="tab.index" slds-tabs-pane-class="slds-p-top_none" slds-tabs="true">\n        <div ng-repeat="subModule in subModuleList" slds-pane="true" data-title="{{subModule.label}}" ng-include="\'Module.tpl.html\'"></div>\n    </div>\n</div>\n'),$templateCache.put("MLSJob.tpl.html",'<div ng-controller="AdminConsoleController" ng-init="initApp(\'MLSJob\',\'Multi-Language Support Jobs\')">\n    <div ng-include="\'SubHeader.tpl.html\'"></div>\n    <div class="job-wrapper">\n        <div class="job-section slds-p-around_small slds-has-divider_bottom">\n            <div class="job-content slds-clearfix">\n                <div class="job-detail slds-float_left">\n                    <div class="job-label">\n                        <a href="javascript:void(0)" ng-click="isTranslationJobCollapsed = !isTranslationJobCollapsed">{{labels.CreateTranslationJobLabel}}</a>\n                    </div>\n                    <div class="job-desc slds-m-top_xx-small">{{labels.CreateTranslationJobDesc}}</div>\n                </div>\n                <div class="job-start slds-float_right">\n                    <button type="button" ng-click="isTranslationJobCollapsed = true; startTranslationJob();" class="slds-button slds-button_brand">{{labels.StartDT}}</button>\n                </div>\n            </div>\n            <div ng-if="translationJobsList.length != 0" ng-show="isTranslationJobCollapsed">\n                <table class="slds-table slds-m-top_small slds-no-row-hover slds-table_fixed-layout">\n                    <thead>\n                        <tr>\n                            <th class="slds-cell-wrap">{{labels.JobName}}</th>\n                            <th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.status}}</th>\n                            <th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.totalJobItems}}</th>\n                            <th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.jobItemsProcessed}}</th>\n                            <th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.createdDate}}</th>\n                            <th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.completedDate}}</th>\n                            <th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.extendedStatus}}</th>\n                        </tr>\n                    </thead>\n                    <tbody>\n                        <tr ng-class="{ \'slds-theme_default\': job.Status == \'Queued\',\n                                        \'slds-theme_default\': job.Status == \'Holding\',\n                                        \'slds-theme_default\': job.Status == \'Preparing\',\n                                        \'slds-theme_success\': job.Status == \'Completed\',\n                                        \'slds-theme_info\': job.Status == \'Aborted\',\n                                        \'slds-theme_warning\': job.Status == \'Processing\',\n                                        \'slds-theme_error\': job.Status == \'Failed\'}"\n                            ng-repeat="job in translationJobsList track by $index">\n                            <td class="slds-cell-wrap">\n                                <p>{{labels.TranslationJobLabel}}</p>\n                            </td>\n                            <td class="slds-cell-wrap">\n                                <p>{{job.Status}}</p>\n                            </td>\n                            <td class="slds-cell-wrap">\n                                <p>{{job.TotalJobItems}}</p>\n                            </td>\n                            <td class="slds-cell-wrap">\n                                <p>{{job.JobItemsProcessed}}</p>\n                            </td>\n                            <td class="slds-cell-wrap">\n                                <p>{{ job.CreatedDate | date : \'short\' }}</p>\n                            </td>\n                            <td class="slds-cell-wrap">\n                                <p>{{ job.CompletedDate | date : \'short\' }}</p>\n                            </td>\n                            <td class="slds-cell-wrap">\n                                <p>{{job.ExtendedStatus}}</p>\n                            </td>\n                        </tr>\n                    </tbody>\n                </table>\n            </div>\n        </div>\n        <div class="job-section slds-p-around_small slds-has-divider_bottom">\n            <div class="job-content slds-clearfix">\n                <div class="job-detail slds-float_left">\n                    <div class="job-label">\n                        <a href="javascript:void(0)" ng-click="isTranslationCacheJobCollapsed = !isTranslationCacheJobCollapsed">{{labels.CreateTranslationCacheJobLabel}}</a>\n                    </div>\n                    <div class="job-desc slds-m-top_xx-small">{{labels.CreateTranslationCacheJobDesc}}</div>\n                </div>\n                <div class="job-start slds-float_right">\n                    <button type="button" ng-click="isTranslationCacheJobCollapsed = true; startTranslationCacheJob();" class="slds-button slds-button_brand">{{labels.StartDT}}</button>\n                </div>\n            </div>\n            <div ng-if="translationCacheJobsList.length != 0" ng-show="isTranslationCacheJobCollapsed">\n                <table class="slds-table slds-m-top_small slds-no-row-hover slds-table_fixed-layout">\n                    <thead>\n                        <tr>\n                            <th class="slds-cell-wrap">{{labels.JobName}}</th>\n                            <th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.status}}</th>\n                            <th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.totalJobItems}}</th>\n                            <th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.jobItemsProcessed}}</th>\n                            <th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.createdDate}}</th>\n                            <th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.completedDate}}</th>\n                            <th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.extendedStatus}}</th>\n                        </tr>\n                    </thead>\n                    <tbody>\n                        <tr ng-class="{ \'slds-theme_default\': job.Status == \'Queued\',\n                                        \'slds-theme_default\': job.Status == \'Holding\',\n                                        \'slds-theme_default\': job.Status == \'Preparing\',\n                                        \'slds-theme_success\': job.Status == \'Completed\',\n                                        \'slds-theme_info\': job.Status == \'Aborted\',\n                                        \'slds-theme_warning\': job.Status == \'Processing\',\n                                        \'slds-theme_error\': job.Status == \'Failed\'}"\n                            ng-repeat="job in translationCacheJobsList track by $index">\n                            <td class="slds-cell-wrap">\n                                <p>{{labels.CachedTranslationJobLabel}}</p>\n                            </td>\n                            <td class="slds-cell-wrap">\n                                <p>{{job.Status}}</p>\n                            </td>\n                            <td class="slds-cell-wrap">\n                                <p>{{job.TotalJobItems}}</p>\n                            </td>\n                            <td class="slds-cell-wrap">\n                                <p>{{job.JobItemsProcessed}}</p>\n                            </td>\n                            <td class="slds-cell-wrap">\n                                <p>{{ job.CreatedDate | date : \'short\' }}</p>\n                            </td>\n                            <td class="slds-cell-wrap">\n                                <p>{{ job.CompletedDate | date : \'short\' }}</p>\n                            </td>\n                            <td class="slds-cell-wrap">\n                                <p>{{job.ExtendedStatus}}</p>\n                            </td>\n                        </tr>\n                    </tbody>\n                </table>\n            </div>\n        </div>\n        <div class="job-section slds-p-around_small slds-has-divider_bottom">\n            <div class="job-content slds-clearfix">\n                <div class="job-detail slds-float_left">\n                    <div class="job-label">\n                        <a href="javascript:void(0)">{{labels.LoadDefaultObjectFieldMLS}}</a>\n                    </div>\n                    <div class="job-desc slds-m-top_x-small">{{labels.LoadDefaultObjectFieldMLSDesc}}</div>\n                </div>\n                <div class="job-start slds-float_right">\n                    <button type="button" ng-click="loadDefaultObjectFieldsConfigMLS();" class="slds-button  slds-button_brand">{{labels.StartDT}}</button>\n                </div>\n            </div>\n        </div>\n    </div>\n</div>\n'),$templateCache.put("MaintenanceJob.tpl.html",'<div ng-controller="AdminConsoleController" ng-init="initApp(\'maintenanceJobs\', labels.CMTOptionMaintenanceJobsLabel)">\n\t<div ng-include="\'SubHeader.tpl.html\'"></div>\n\t<div class="job-wrapper">\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom">\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)" ng-click="jobWrapper.startRootAccountJob.jobListToggle = !jobWrapper.startRootAccountJob.jobListToggle">{{labels.AccountHierarchyMaintenance}}</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_xx-small">{{labels.JobRestoreAccountHierarchy}}</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button type="button" ng-click="confirmationPopup(jobWrapper.startRootAccountJob);" class="slds-button slds-button_brand">{{labels.StartDT}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t\t<div ng-if="rootAccountJobsList.length != 0" ng-show="jobWrapper.startRootAccountJob.jobListToggle">\n\t\t\t\t<table class="slds-table slds-m-top_small slds-no-row-hover slds-table_fixed-layout">\n\t\t\t\t\t<thead>\n\t\t\t\t\t\t<tr>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{labels.JobName}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.status}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.totalJobItems}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.jobItemsProcessed}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.createdDate}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.completedDate}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.extendedStatus}}</th>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t</thead>\n\t\t\t\t\t<tbody>\n\t\t\t\t\t\t<tr ng-class="{\t\'slds-theme_default\': job.Status == \'Queued\',\n\t\t\t\t\t\t\t\t\t\t\'slds-theme_default\': job.Status == \'Holding\',\n\t\t\t\t\t\t\t\t\t\t\'slds-theme_default\': job.Status == \'Preparing\',\n\t\t\t\t\t\t\t\t\t\t\'slds-theme_success\': job.Status == \'Completed\',\n\t\t\t\t\t\t\t\t\t\t\'slds-theme_info\': job.Status == \'Aborted\',\n\t\t\t\t\t\t\t\t\t\t\'slds-theme_warning\': job.Status == \'Processing\',\n\t\t\t\t\t\t\t\t\t\t\'slds-theme_error\': job.Status == \'Failed\'}"\n\t\t\t\t\t\t\tng-repeat="job in rootAccountJobsList track by $index">\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{labels.ResolveRootAccounts}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{job.Status}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{job.TotalJobItems}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{job.JobItemsProcessed}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{ job.CreatedDate | date : \'short\' }}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{ job.CompletedDate | date : \'short\' }}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{job.ExtendedStatus}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t</tbody>\n\t\t\t\t</table>\n\t\t\t</div>\n\t\t</div>\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom">\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)">{{labels.InterfaceImplementationMaintenanceRestore}}</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_xx-small">{{labels.JobRestoreImplementations}}</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button type="button" ng-click="confirmationPopup(jobWrapper.resetInterfaceImplementations);" class="slds-button slds-button_brand">{{labels.StartDT}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t</div>\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom">\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)">{{labels.InterfaceImplementationMaintenanceMerge}}</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_xx-small">{{labels.MergeInterfaceImplementations}}</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button type="button" ng-click="confirmationPopup(jobWrapper.mergeInterfaceImplementations);" class="slds-button slds-button_brand">{{labels.StartDT}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t</div>\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom">\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)">{{labels.FieldMapsMaintenance}}</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_xx-small">{{labels.JobRestoreFieldMaps}}</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button type="button" ng-click="confirmationPopup(jobWrapper.resetFieldMaps);" class="slds-button slds-button_brand">{{labels.StartDT}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t</div>\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom">\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)">{{labels.ObjectMapMaintenance}}</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_xx-small">{{labels.ObjectMapMaintenanceDescription}}</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button type="button" ng-click="confirmationPopup(jobWrapper.resetObjectMaps);" class="slds-button slds-button_brand">{{labels.StartDT}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t</div>\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom" >\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)" ng-click="jobWrapper.startXLIBatchValidationJob.jobListToggle = !jobWrapper.startXLIBatchValidationJob.jobListToggle">{{labels.BatchValidation}}</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_xx-small">{{labels.StartBatchJobValidation}}</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button type="button" ng-click="confirmationPopup(jobWrapper.startXLIBatchValidationJob);" class="slds-button slds-button_brand">{{labels.StartDT}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t\t<div  ng-show="jobWrapper.startXLIBatchValidationJob.jobListToggle">\n\t\t\t\t<table class="slds-table slds-m-top_small slds-no-row-hover slds-table_fixed-layout">\n\t\t\t\t\t<thead>\n\t\t\t\t\t\t<tr>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{labels.JobName}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.status}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.totalJobItems}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.jobItemsProcessed}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.createdDate}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.completedDate}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.extendedStatus}}</th>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t</thead>\n\t\t\t\t\t<tbody>\n\t\t\t\t\t\t<tr ng-class="{\t\'slds-theme_default\': job.Status == \'Queued\',\n\t\t\t\t\t\t\t\t\t\t\'slds-theme_default\': job.Status == \'Holding\',\n\t\t\t\t\t\t\t\t\t\t\'slds-theme_default\': job.Status == \'Preparing\',\n\t\t\t\t\t\t\t\t\t\t\'slds-theme_success\': job.Status == \'Completed\',\n\t\t\t\t\t\t\t\t\t\t\'slds-theme_info\': job.Status == \'Aborted\',\n\t\t\t\t\t\t\t\t\t\t\'slds-theme_warning\': job.Status == \'Processing\',\n\t\t\t\t\t\t\t\t\t\t\'slds-theme_error\': job.Status == \'Failed\'}"\n\t\t\t\t\t\t\tng-repeat="job in XLIBatchJobValidationList track by $index">\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{labels.BatchValidation}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{job.Status}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{job.TotalJobItems}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{job.JobItemsProcessed}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{ job.CreatedDate | date : \'short\' }}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{ job.CompletedDate | date : \'short\' }}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{job.ExtendedStatus}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t</tbody>\n\t\t\t\t</table>\n\t\t\t</div>\n\t\t</div>\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom">\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)">{{labels.ResetXLIValiatonData}}</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_xx-small">{{labels.ValidateOrdersReset}}</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button type="button" ng-click="confirmationPopup(jobWrapper.resetXLIBatchValidationData);" class="slds-button slds-button_brand">{{labels.StartDT}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t</div>\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom">\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)" ng-click="jobWrapper.startProductHierarchyJob.jobListToggle = !jobWrapper.startProductHierarchyJob.jobListToggle">{{labels.ProductHierarchyMaintenanceTitle}}</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_xx-small">{{labels.ProductHierarchyMaintenanceDescription}}</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button type="button" ng-click="confirmationPopup(jobWrapper.startProductHierarchyJob);" class="slds-button slds-button_brand">{{labels.StartDT}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t\t<div ng-if="productHierarchyJobsList.length != 0" ng-show="jobWrapper.startProductHierarchyJob.jobListToggle">\n\t\t\t\t<table class="slds-table slds-m-top_small slds-no-row-hover slds-table_fixed-layout">\n\t\t\t\t\t<thead>\n\t\t\t\t\t\t<tr>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{labels.JobName}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.status}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.totalJobItems}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.jobItemsProcessed}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.createdDate}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.completedDate}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.extendedStatus}}</th>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t</thead>\n\t\t\t\t\t<tbody>\n\t\t\t\t\t\t<tr ng-class="{\t\'slds-theme_default\': job.Status == \'Queued\',\n\t\t\t\t\t\t\t\t\t\t\'slds-theme_default\': job.Status == \'Holding\',\n\t\t\t\t\t\t\t\t\t\t\'slds-theme_default\': job.Status == \'Preparing\',\n\t\t\t\t\t\t\t\t\t\t\'slds-theme_success\': job.Status == \'Completed\',\n\t\t\t\t\t\t\t\t\t\t\'slds-theme_info\': job.Status == \'Aborted\',\n\t\t\t\t\t\t\t\t\t\t\'slds-theme_warning\': job.Status == \'Processing\',\n\t\t\t\t\t\t\t\t\t\t\'slds-theme_error\': job.Status == \'Failed\'}"\n\t\t\t\t\t\t\tng-repeat="job in productHierarchyJobsList track by $index">\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{labels.ProductHierarchyMaintenanceJobName}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{job.Status}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{job.TotalJobItems}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{job.JobItemsProcessed}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{ job.CreatedDate | date : \'short\' }}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{ job.CompletedDate | date : \'short\' }}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{job.ExtendedStatus}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t</tbody>\n\t\t\t\t</table>\n\t\t\t</div>\n\t\t</div>\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom">\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)">{{labels.ClearManagedPlatformCache}}</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_xx-small">{{labels.ClearManagedPlatformCacheDescription}}</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button type="button" ng-click="confirmationPopup(jobWrapper.clearPlatformCache);" class="slds-button slds-button_brand">{{labels.StartDT}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t</div>\n\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom">\n\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)" ng-click="jobWrapper.refreshPriceBook.jobListToggle = !jobWrapper.refreshPriceBook.jobListToggle">{{labels.RefreshPricebook}}</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_x-small">{{labels.RefreshPricebookDescription}}</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button id="idRefreshPriceBookStartButton" type="button" ng-click="confirmationPopup(jobWrapper.refreshPriceBook);" class="slds-button  slds-button--brand">{{labels.StartDT}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t\t<div ng-if="refreshPriceBookJobList.length != 0" ng-show="jobWrapper.refreshPriceBook.jobListToggle">\n\t\t\t\t\t<table class="slds-table slds-m-top_small slds-no-row-hover slds-table_fixed-layout">\n\t\t\t\t\t\t<tr>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{labels.JobName}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.status}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.totalJobItems}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.jobItemsProcessed}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.createdDate}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.completedDate}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.extendedStatus}}</th>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t\t<tr ng-class="{\t\'slds-theme_default\': job.Status == \'Queued\',\n'+"\t\t\t\t\t\t\t\t\t\t'slds-theme_default': job.Status == 'Holding',\n\t\t\t\t\t\t\t\t\t\t'slds-theme_default': job.Status == 'Preparing',\n\t\t\t\t\t\t\t\t\t\t'slds-theme_success': job.Status == 'Completed',\n\t\t\t\t\t\t\t\t\t\t'slds-theme_info': job.Status == 'Aborted',\n\t\t\t\t\t\t\t\t\t\t'slds-theme_warning': job.Status == 'Processing',\n\t\t\t\t\t\t\t\t\t\t'slds-theme_error': job.Status == 'Failed'}\"\n\t\t\t\t\t\t\tng-repeat=\"job in refreshPriceBookJobList track by $index\">\n\t\t\t\t\t\t  \t<td class=\"slds-cell-wrap\">\n\t\t\t\t\t\t\t  \t<p>{{labels.RefreshPricebook}}</p>\n\t\t\t\t\t\t  \t</td>\n\t\t\t\t\t\t\t<td class=\"slds-cell-wrap\">\n\t\t\t\t\t\t\t\t<p>{{job.Status}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class=\"slds-cell-wrap\">\n\t\t\t\t\t\t\t\t<p>{{job.TotalJobItems}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class=\"slds-cell-wrap\">\n\t\t\t\t\t\t\t\t<p>{{job.JobItemsProcessed}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class=\"slds-cell-wrap\">\n\t\t\t\t\t\t\t\t<p>{{ job.CreatedDate | date : 'short' }}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class=\"slds-cell-wrap\">\n\t\t\t\t\t\t\t\t<p>{{ job.CompletedDate | date : 'short' }}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class=\"slds-cell-wrap\">\n\t\t\t\t\t\t\t\t<p>{{job.ExtendedStatus}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t</table>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t</div>\n\t</div>\n</div>\n"),
$templateCache.put("Module.tpl.html",'<div class="slds-p-around_small" ng-if="!showLoading">\n\t<ng-form name="moduleForm">\n\t\t<div class="slds-input-has-icon slds-input-has-icon_left">\n\t\t\t<slds-svg-icon sprite="\'utility\'" icon="\'search\'" extra-classes="\'slds-input__icon slds-input__icon_left\'"></slds-svg-icon>\n\t\t\t<input type="search" placeholder="{{labels.SearchLabel}}"\n\t\t\tng-model="search.name" class="slds-input">\n\t\t</div>\n\t\t<table class="slds-table slds-table_bordered slds-table_cell-buffer slds-m-top_medium">\n\t  \t\t<thead>\n\t    \t\t<tr class="slds-text-heading_label">\n\t\t\t\t\t<th scope="col" data-title="{{column.label}}" ng-repeat="column in subModuleList[activeTab].metaDataList">\n\t\t\t\t\t\t<div class="slds-truncate">{{column.label}}</div>\n\t\t\t\t\t</th>\n\t\t\t\t\t<th scope="col">\n\t\t\t\t\t\t<div class="slds-p-horizontal_x-small">{{labels.ActionLabel}}</div>\n\t    \t\t\t</th>\n\t    \t\t</tr>\n\t  \t\t</thead>\n\t  \t\t<tbody>\n\t    \t\t<tr scope="row" ng-repeat="record in subModuleList[activeTab].records| filter:filterList track by $index">\n\t\t\t\t\t<td ng-repeat="column in subModuleList[activeTab].metaDataList" data-label="{{record[column.name]}}" title="{{record[column.name]}}" class="slds-cell-wrap">\n\n\t\t\t\t\t\t<div ng-if="!record.editMode" data-title="{{record[column.name]}}">{{record[column.name]}}</div>\n\t\t\t\t\t\t<div ng-if="record.editMode">\n\t\t\t\t\t\t\t<div ng-if="column.name === \'Name\' && subModuleList[activeTab].name !== \'configurations\'" data-title="{{record[column.name]}}">\n\t\t\t\t\t\t\t\t{{record[column.name]}}\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t<div ng-if="column.name === \'Name\' && subModuleList[activeTab].name === \'configurations\'">\n\t\t\t\t\t\t\t\t<input type="text" ng-required="true" ng-model="record[column.name]" ng-change="verifyDuplicate(column.name)" ng-class="{\'ng-invalid-required\':record.isDuplicate}" class="slds-input" data-title="{{record[column.name]}}">\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t<div ng-if="column.name === nsPrefix + \'IsEditable__c\'">\n\t\t\t\t\t\t\t\t<select ng-options="boolean.value as boolean.label for boolean in booleanSelectionOptions" ng-model="record[column.name]" ng-required="true" class="slds-select">\n\t\t\t\t\t\t\t\t\t<option value="" ng-disabled="true">{{labels.SelectLabel}}</option>\n\t\t\t\t\t\t\t\t</select>\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t<div ng-if="column.name === nsPrefix + \'ObjectName__c\' || column.name === nsPrefix  + \'Object_Name__c\'" data-title="{{record[column.name]}}">\n\t\t\t\t\t\t\t\t<select ng-options="object.name as object.label for object in allObjectList" ng-model="record[column.name]" ng-required="true" class="slds-select" ng-change="record[nsPrefix  + \'FieldName__c\'] = \'\' ">\n\t\t\t\t\t\t\t\t\t<option value="" ng-disabled="true">{{labels.SelectLabel}}</option>\n\t\t\t\t\t\t\t\t</select>\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t<div ng-if="column.name === nsPrefix + \'FieldName__c\' ">\n\t\t\t\t\t\t\t\t<div class="slds-input-has-icon slds-input-has-icon_right">\n\t\t\t\t\t\t\t\t\t<a href="javascript:void(0)" ng-class="{\'disableIcon\': !record[nsPrefix + \'ObjectName__c\'] && !record[nsPrefix + \'Object_Name__c\']}">\n\t\t\t\t\t\t\t\t\t\t<slds-svg-icon sprite="\'utility\'" icon="\'edit\'" extra-classes="\'slds-input__icon\'" ng-click="openFieldSelection(record)"></slds-svg-icon>\n\t\t\t\t\t\t\t\t\t</a>\n\t\t\t\t\t\t\t\t\t<input type="text" ng-required="true" ng-disabled="true" class="slds-input" ng-model="record[column.name]">\n\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t<div ng-if="column.name === nsPrefix + \'Sequence__c\'">\n\t\t\t\t\t\t\t\t<input type="text" ng-model="record[column.name]" ng-change="verifyDuplicate(column.name)" ng-class="{\'ng-invalid-required\':record.isDuplicate}" ng-required="true" class="slds-input" ng-pattern="/^\\d+$/"/>\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t<div ng-if="column.name === nsPrefix + \'Feature__c\'" ng-init="record[column.name]=subModuleList[activeTab].feature">\n\t\t\t\t\t\t\t\t<input type="text" ng-model="record[column.name]" ng-readonly="true" ng-required="true" ng-disabled="true" class="slds-input" data-title="{{record[column.name]}}"/>\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t<div ng-if="column.name === nsPrefix + \'Popup_Page_Id__c\'">\n\t\t\t\t\t\t\t\t<div class="slds-input-has-icon slds-input-has-icon_right">\n\t\t\t\t\t\t\t\t \t<a href="javascript:void(0);">\n\t\t\t\t\t\t\t\t\t\t<slds-svg-icon sprite="\'utility\'" icon="\'search\'" extra-classes="\'slds-input__icon slds-icon-text-default\'" ng-click="openPageSelection(record)"></slds-svg-icon>\n\t\t\t\t\t\t\t\t\t</a>\n\t\t\t\t\t\t\t\t\t<input type="text" ng-required="true" ng-readonly="true" ng-disabled="true" class="slds-input" ng-model="record[column.name]" data-title="{{record[column.name]}}">\n\t\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t<div ng-if="column.name === nsPrefix + \'SetupValue__c\'">\n\t\t\t\t\t\t\t\t<input type="text" ng-required="true" ng-model="record[column.name]" class="slds-input" data-title="{{record[column.name]}}">\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t\t<div ng-if="column.name === nsPrefix + \'Value__c\'">\n\t\t\t\t\t\t\t\t<input type="text" ng-required="true" ng-model="record[column.name]" class="slds-input" data-title="{{record[column.name]}}">\n\t\t\t\t\t\t\t</div>\n\t\t\t\t\t\t</div>\n\t\t\t\t\t</td>\n\t\t\t\t\t<td data-label="Action" title="Action">\n\t\t\t\t\t\t<a href="javascript:void(0);" ng-class="{\'disableIcon\': record.editMode===true}" class="slds-m-right_small">\n\t\t\t\t\t\t\t<slds-svg-icon sprite="\'utility\'" icon="\'edit\'" extra-classes="\'slds-icon_xx-small slds-icon-text-default\'" ng-click="record.editMode = true"></slds-svg-icon>\n\t\t\t\t\t\t</a>\n\t\t\t\t\t\t<a href="javascript:void(0);">\n\t\t\t\t\t\t  \t<slds-svg-icon sprite="\'utility\'" icon="\'delete\'" extra-classes="\'slds-icon_xx-small slds-icon-text-default slds-m-left_x-small\'" ng-click="delete(record, $index)"></slds-svg-icon>\n\t\t\t\t\t  \t</a>\n\t\t\t\t\t</td>\n\t    \t\t</tr>\n\t  \t\t</tbody>\n\t\t</table>\n\t\t<div class="slds-grid slds-grid_align-center slds-button-group slds-m-top_medium" role="group">\n\t\t\t<button class="slds-button slds-button_neutral" ng-click="add(subModuleList[activeTab].records)">{{labels.AddLabel}}</button>\n\t\t\t<button class="slds-button slds-button_neutral" ng-click="save()" ng-disabled="isDuplicate || moduleForm.$invalid || checkSaveMode()">{{labels.SaveLabel}}</button>\n\t\t</div>\n\t</ng-form>\n</div>\n'),$templateCache.put("PageSelectionModal.tpl.html",'<div class="page-selection slds-modal slds-fade-in-open" aria-hidden="false" role="dialog">\n    <div class="slds-modal__container">\n        <div class="slds-modal__header">\n            <button class="slds-button slds-button_icon-inverse slds-modal__close" ng-click="$hide()">\n                <svg aria-hidden="true" class="slds-button__icon slds-button__icon_large">\n                    <use xlink:href="{{SLDSICON.CLOSE}}"></use>\n                </svg>\n                <span class="slds-assistive-text">{{labels.Close}}</span>\n            </button>\n            <h2 class="slds-text-heading_medium">{{confirmationTitle}}</h2>\n        </div>\n        <div class="slds-modal__content slds-p-around_medium">\n            <div class="slds-spinner_container" ng-if="showLoading">\n                <div class="slds-spinner_brand slds-spinner slds-spinner_medium" aria-hidden="false" role="alert">\n                    <div class="slds-spinner__dot-a"></div>\n                    <div class="slds-spinner__dot-b"></div>\n                </div>\n            </div>\n            <div class="search-wrapper" ng-if="!showLoading">\n                <svg aria-hidden="true" class="slds-icon">\n                    <use xlink:href="{{SLDSICON.SEARCH}}"></use>\n                </svg>\n                <input type="search" placeholder="Search" ng-model="search"/>\n                <button class="slds-button" ng-click="searchPage(search)">{{labels.SearchLabel}}</button>\n            </div>\n            <table class="table-wrapper slds-table slds-table_bordered slds-table_cell-buffer slds-m-top_medium" ng-if="!showLoading && pageList && pageList.length !== 0">\n                <thead>\n                    <tr class="slds-text-heading_label">\n                        <th scope="col">\n                            <div class="slds-truncate">{{labels.SelectLabel}}</div>\n                        </th>\n                        <th scope="col">\n                            <div class="slds-truncate">{{labels.NameLabel}}</div>\n                        </th>\n                        <th scope="col">\n                            <div class="slds-truncate">{{labels.LabelLabel}}</div>\n                        </th>\n                        <th scope="col">\n                            <div class="slds-truncate">{{labels.ApiVersionLabel}}</div>\n                        </th>\n                    </tr>\n                </thead>\n                <tbody>\n                    <tr ng-repeat="p in pageList track by $index">\n                        <td style="width:10%;">\n                            <input type="radio" ng-model="pageWrapper.page" ng-value="p" name="vfpage">\n                        </td>\n                        <td style="width:30%;">\n                            <div class="slds-truncate">{{p.Name}}</div>\n                        </td>\n                        <td style="width:30%;">\n                            <div class="slds-truncate">{{p.MasterLabel}}</div>\n                        </td>\n                        <td style="width:30%;">\n                            <div class="slds-truncate">{{p.ApiVersion}}</div>\n                        </td>\n                    </tr>\n                </tbody>\n            </table>\n            <div class="error" ng-if="!showLoading && (!pageList || pageList.length === 0)">\n                <p>{{labels.NoPageFoundError}}</p>\n            </div>\n        </div>\n        <div class="slds-modal__footer">\n            <button type="button" class="slds-button slds-button_neutral" ng-click="$hide()">{{cancelActionLbl}}</button>\n            <button type="button" class="slds-button slds-button_neutral slds-button_brand" ng-click="confirmAction()" ng-disabled="!pageWrapper.page.Name || pageWrapper.page.Name === \'\' ">{{confirmActionLbl}}</button>\n        </div>\n    </div>\n</div>\n<div class="slds-backdrop slds-backdrop_open"></div>\n'),$templateCache.put("PerformanceJob.tpl.html",'<div ng-controller="AdminConsoleController" ng-init="initApp(\'PerformanceJobs\', labels.CMTOptionPerformanceJobsLabel)">\n\t<div ng-include="\'SubHeader.tpl.html\'"></div>\n\t<div class="slds-theme_shade">\n\t\t<div class="job-wrapper slds-p-around_medium">\n\t\t\t<div class="job-section slds-m-top_x-small slds-has-divider_bottom">\n\t\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t\t<a href="javascript:void(0)">{{labels.XLIAPILabel}}</a>\n\t\t\t\t\t\t</div>\n\t\t\t\t\t\t<div class="job-desc slds-m-top_x-small">{{labels.XLIAPIDesc}}</div>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t\t<button id="addOrderLineItemJobButton" type="button" ng-click="showTestResults = true; addOrderLineItemJob();" class="slds-button  slds-button_brand">{{labels.StartDT}}</button>\n\t\t\t\t\t</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="row">\n\t\t\t\t\t<div id="addOrderLineItemJobStatus" class="col-md-12 col-sm-12 col-xs-12">\n\t\t\t\t\t\t<div ng-if="hasErrors" style="color : red" class="alert alert-danger" role="alert">{{errorMessage}}</div>\n\t\t\t\t\t</div>\n\t\t\t\t</div>\n\t\t\t\t<div ng-if="result != 0" ng-show="showTestResults">\n\t\t\t\t\t<table class="slds-table slds-m-top_small slds-no-row-hover slds-table_fixed-layout">\n\t\t\t\t\t\t<tr ng-class="slds-theme_success" style="background-color : #cfeef8">\n\t\t\t\t\t\t\t<th class="slds-cell-wrap" style="font-weight:900">API</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap" style="font-weight:900">Time</th>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t\t<tr>\n\t\t\t\t\t  \t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t  \t\t<p>{{labels.AddXLILabel}}</p>\n\t\t\t\t\t  \t\t</td>\n\t\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t\t<p>{{result.AddOLITime}} <span ng-bind="{{result.AddOLITime}}"></span><i ng-hide="result.AddOLITime"  class="icon icon-refresh icon-spin" >...</i></p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t</table>\n\t\t\t\t</div>\n\t\t\t</div>\n\n\t\t</div>\n\t</div>\n</div>\n'),$templateCache.put("PowerUpdate.tpl.html",'<div ng-controller="CustomSettingsController" ng-init="initApp(\'powerupdate\')">\n\t<div ng-include="\'SubHeader.tpl.html\'"></div>\n\t<div class="slds-p-around_small" slds-active-pane="tab.index" slds-tabs-pane-class="slds-p-top_none" slds-tabs="true">\n\t\t<div ng-repeat="subModule in subModuleList" slds-pane="true" data-title="{{subModule.label}}" ng-include="\'Module.tpl.html\'"></div>\n\t</div>\n</div>'),$templateCache.put("ProductManagementConfig.tpl.html",'<div ng-controller="CustomSettingsController" ng-init="initApp(\'prodMgmtCfg\')">\n\t<div ng-include="\'SubHeader.tpl.html\'"></div>\n\t<div class="slds-p-around_small" slds-active-pane="tab.index" slds-tabs-pane-class="slds-p-top_none" slds-tabs="true">\n\t\t<div ng-repeat="subModule in subModuleList" slds-pane="true" data-title="{{subModule.label}}" ng-include="\'Module.tpl.html\'"></div>\n\t</div>\n</div>'),$templateCache.put("ReviewCart.tpl.html",'<div ng-controller="CustomSettingsController" ng-init="initApp(\'reviewcart\')">\n\t<div ng-include="\'SubHeader.tpl.html\'"></div>\n\t<div class="slds-p-around_small" slds-active-pane="tab.index" slds-tabs-pane-class="slds-p-top_none" slds-tabs="true">\n\t\t<div ng-repeat="subModule in subModuleList" slds-pane="true" data-title="{{subModule.label}}" ng-include="\'Module.tpl.html\'"></div>\n\t</div>\n</div>'),$templateCache.put("SubHeader.tpl.html",'<div class="slds-clearfix slds-p-around_small">\n\t<span class="slds-text-heading_medium slds-float_left">{{module.label}}</span>\n\t<span class="slds-float_right">\n\t\t<button class="slds-button slds-button_neutral" ng-click="showClickedMenu(\'Dashboard\')">{{labels.BackToDashboardLabel}}</button>\n\t</span>\n</div>\n'),$templateCache.put("UpgradeJob.tpl.html",'<div ng-controller="AdminConsoleController" ng-init="initApp(\'upgradeJobs\',labels.CMTOptionUpgradeJobsLabel)">\n\t<div ng-include="\'SubHeader.tpl.html\'"></div>\n\t<div class="job-wrapper">\n\t\t<!--\n\t\t<div class="job-section slds-has-divider_bottom">\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)" ng-click="isAttributesBindingJobCollapsed = !isAttributesBindingJobCollapsed">Attributes Binding Upgrade</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_x-small">This job will populate the bound attribute fields from the JSON to the specified object fields based on the entity class definition</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-objectName slds-p-left_medium slds-float_left">\n\t\t\t\t\t<input id="idAttributesBindingObjects" ng-required="true" ng-model="upgradeTab.attributesBindingObjects" class="slds-input" type="text" placeholder="Object name" />\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button id="idAttributesBindingButton"type="button" ng-disabled="validateInput()" ng-click="isAttributesBindingJobCollapsed = true; startAttributesBindingJob();" class="slds-button  slds-button_brand">{{labels.StartDT}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t\t<div ng-if="attributesBindingJobsList.length != 0" ng-show="isAttributesBindingJobCollapsed">\n\t\t\t\t<table class="slds-table slds-m-top_small slds-no-row-hover slds-table_fixed-layout">\n\t\t\t\t\t<tr>\n\t\t\t\t\t\t<th class="slds-cell-wrap">{{labels.JobName}}</th>\n\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.status}}</th>\n\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.totalJobItems}}</th>\n\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.jobItemsProcessed}}</th>\n\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.createdDate}}</th>\n\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.completedDate}}</th>\n\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.extendedStatus}}</th>\n\t\t\t\t\t</tr>\n\t\t\t\t\t<tr ng-class="{\t\'slds-theme_default\': job.Status == \'Queued\',\n\t\t\t\t\t\t\t\t\t\'slds-theme_default\': job.Status == \'Holding\',\n\t\t\t\t\t\t\t\t\t\'slds-theme_default\': job.Status == \'Preparing\',\n\t\t\t\t\t\t\t\t\t\'slds-theme_success\': job.Status == \'Completed\',\n\t\t\t\t\t\t\t\t\t\'slds-theme_info\': job.Status == \'Aborted\',\n\t\t\t\t\t\t\t\t\t\'slds-theme_warning\': job.Status == \'Processing\',\n\t\t\t\t\t\t\t\t\t\'slds-theme_error\': job.Status == \'Failed\'}"\n\t\t\t\t\t\tng-repeat="job in attributesBindingJobsList track by $index">\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>Attributes Binding Upgrade</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>{{job.Status}}</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>{{job.TotalJobItems}}</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>{{job.JobItemsProcessed}}</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>{{ job.CreatedDate | date : \'short\' }}</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>{{ job.CompletedDate | date : \'short\' }}</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t\t<td class="slds-cell-wrap">\n\t\t\t\t\t\t\t<p>{{job.ExtendedStatus}}</p>\n\t\t\t\t\t\t</td>\n\t\t\t\t\t</tr>\n\t\t\t\t</table>\n\t\t\t</div>\n\t\t</div>\n\t\t-->\n\t\t<div class="job-section slds-p-around_small slds-has-divider_bottom">\n\t\t\t<div class="job-content slds-clearfix">\n\t\t\t\t<div class="job-detail slds-float_left">\n\t\t\t\t\t<div class="job-label">\n\t\t\t\t\t\t<a href="javascript:void(0)" ng-click="isRootProductChildItemJobCollapsed = !isRootProductChildItemJobCollapsed">{{labels.RootPCIUpgrade}}</a>\n\t\t\t\t\t</div>\n\t\t\t\t\t<div class="job-desc slds-m-top_x-small">{{labels.RootPCIUpgradeDesc}}</div>\n\t\t\t\t</div>\n\t\t\t\t<div class="job-start slds-float_right">\n\t\t\t\t\t<button type="button" ng-click="isRootProductChildItemJobCollapsed = true; startRootProductChildItemJob();" class="slds-button  slds-button_brand">{{labels.StartDT}}</button>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t\t<div ng-if="rootProductChildItemJobsList.length != 0" ng-show="isRootProductChildItemJobCollapsed">\n\t\t\t\t<table class="slds-table slds-m-top_small slds-no-row-hover slds-table_fixed-layout">\n\t\t\t\t\t<thead>\n\t\t\t\t\t\t<tr>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{labels.JobName}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.status}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.totalJobItems}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.jobItemsProcessed}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.createdDate}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.completedDate}}</th>\n\t\t\t\t\t\t\t<th class="slds-cell-wrap">{{asyncApexJobFieldsLabels.extendedStatus}}</th>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t</thead>\n\t\t\t\t\t<tbody>\n\t\t\t\t\t\t<tr ng-class="{\t\'slds-theme_default\': job.Status == \'Queued\',\n'+"\t\t\t\t\t\t\t\t\t\t'slds-theme_default': job.Status == 'Holding',\n\t\t\t\t\t\t\t\t\t\t'slds-theme_default': job.Status == 'Preparing',\n\t\t\t\t\t\t\t\t\t\t'slds-theme_success': job.Status == 'Completed',\n\t\t\t\t\t\t\t\t\t\t'slds-theme_info': job.Status == 'Aborted',\n\t\t\t\t\t\t\t\t\t\t'slds-theme_warning': job.Status == 'Processing',\n\t\t\t\t\t\t\t\t\t\t'slds-theme_error': job.Status == 'Failed'}\"\n\t\t\t\t\t\t\tng-repeat=\"job in rootProductChildItemJobsList track by $index\">\n\t\t\t\t\t\t\t<td class=\"slds-cell-wrap\">\n\t\t\t\t\t\t\t\t<p>{{labels.RootPCIUpgrade}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class=\"slds-cell-wrap\">\n\t\t\t\t\t\t\t\t<p>{{job.Status}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class=\"slds-cell-wrap\">\n\t\t\t\t\t\t\t\t<p>{{job.TotalJobItems}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class=\"slds-cell-wrap\">\n\t\t\t\t\t\t\t\t<p>{{job.JobItemsProcessed}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class=\"slds-cell-wrap\">\n\t\t\t\t\t\t\t\t<p>{{ job.CreatedDate | date : 'short' }}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class=\"slds-cell-wrap\">\n\t\t\t\t\t\t\t\t<p>{{ job.CompletedDate | date : 'short' }}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t\t<td class=\"slds-cell-wrap\">\n\t\t\t\t\t\t\t\t<p>{{job.ExtendedStatus}}</p>\n\t\t\t\t\t\t\t</td>\n\t\t\t\t\t\t</tr>\n\t\t\t\t\t</tbody>\n\t\t\t\t</table>\n\t\t\t</div>\n\t\t</div>\n\t</div>\n</div>\n"),$templateCache.put("fieldLookup.html",'<div class="slds-grid slds-grid_pull-padded">\n\t\t<div class="fieldsContainer-{{$index}} slds-size_1-of-2"  ng-repeat="fieldSet in fieldSets track by $index" ng-init="outerIndex = $index">\n\t\t\t<select class="slds-select" size="10" ng-change="populateNextTable($index, selectedFields[$index])" data-ng-options="field as field.label+\'<\'+field.name+\'>\' for field in fieldSet | orderBy:\'label\'" data-ng-model="selectedFields[$index]">\n\t\t\t\t<option value="" ng-if="false"></option>\n\t\t\t</select>\t\t\t\t\t\t\t\n\t\t</div>\n</div>')}]);
},{}]},{},[1]);

})();