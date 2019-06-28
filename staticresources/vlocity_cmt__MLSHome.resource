(function(){var fileNsPrefix=function(){"use strict";var scripts=document.getElementsByTagName("script");var lastScript=scripts[scripts.length-1];var scriptName=lastScript.src;var parts=scriptName.split("/");var partsLength=parts.length-1;var thisScript=parts[partsLength--];if(thisScript===""){thisScript=parts[partsLength--]}if(scriptName.indexOf("__")!=-1){while(thisScript.indexOf("__")==-1&&partsLength>=0){thisScript=parts[partsLength];partsLength--}}var lowerCasePrefix=thisScript.indexOf("__")==-1?"":thisScript.substring(0,thisScript.indexOf("__")+2);lowerCasePrefix=lowerCasePrefix===""&&localStorage.getItem("nsPrefix")?localStorage.getItem("nsPrefix"):lowerCasePrefix;if(lowerCasePrefix!==""){lowerCasePrefix=/__$/.test(lowerCasePrefix)?lowerCasePrefix:lowerCasePrefix+"__"}if(lowerCasePrefix.length===0){return function(){lowerCasePrefix=window.nsPrefix?window.nsPrefix:lowerCasePrefix;if(lowerCasePrefix!==""){lowerCasePrefix=/__$/.test(lowerCasePrefix)?lowerCasePrefix:lowerCasePrefix+"__"}return lowerCasePrefix}}else{var resolvedNs=null;return function(){if(resolvedNs){return resolvedNs}try{var tofind=lowerCasePrefix.replace("__","");var name;var scanObjectForNs=function(object,alreadySeen){if(object&&object!==window&&alreadySeen.indexOf(object)==-1){alreadySeen.push(object);Object.keys(object).forEach(function(key){if(key==="ns"){if(typeof object[key]==="string"&&object[key].toLowerCase()===tofind){name=object[key]+"__";return false}}if(Object.prototype.toString.call(object[key])==="[object Array]"){object[key].forEach(function(value){var result=scanObjectForNs(value,alreadySeen);if(result){name=result;return false}})}else if(typeof object[key]=="object"){var result=scanObjectForNs(object[key],alreadySeen);if(result){name=result;return false}}if(name){return false}});if(name){return name}}};if(typeof Visualforce!=="undefined"){scanObjectForNs(Visualforce.remoting.Manager.providers,[])}else{return lowerCasePrefix}if(name){return resolvedNs=name}else{return resolvedNs=lowerCasePrefix}}catch(e){return lowerCasePrefix}}}}();var fileNsPrefixDot=function(){var prefix=fileNsPrefix();if(prefix.length>1){return prefix.replace("__",".")}else{return prefix}};
(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
angular.module(
    'mlsHome',
    ['vlocity','sldsangular', 'drvcomp', 'ngTable']
);

require('./modules/mlsHome/services/mlsService.js');
require('./modules/mlsHome/factories/mlsFactory.js');
require('./modules/mlsHome/templates/templates.js');
require('./modules/mlsHome/controllers/mlsHomeController.js');
require('./modules/mlsHome/config/config.js');
require('./modules/mlsHome/run/run.js');

},{"./modules/mlsHome/config/config.js":2,"./modules/mlsHome/controllers/mlsHomeController.js":3,"./modules/mlsHome/factories/mlsFactory.js":4,"./modules/mlsHome/run/run.js":5,"./modules/mlsHome/services/mlsService.js":6,"./modules/mlsHome/templates/templates.js":7}],2:[function(require,module,exports){
angular.module('mlsHome')
       .config(['remoteActionsProvider', function(remoteActionsProvider){
             var nsPrefixDotNotation = fileNsPrefixDot();
           var remoteActions = {
               doGenericInvoke: {
                   action: nsPrefixDotNotation + 'CardCanvasController.doGenericInvoke',
                   config: {escape: false, buffer: false}
               },
               getObjectPicklistsByName: {
                  action: nsPrefixDotNotation + 'MLSHomeController.getObjectPicklistsByName',
                  config: {escape: false, buffer: false}
               }
           };

           // Only desktop would need RemoteActions
           remoteActionsProvider.setRemoteActions(remoteActions || {});
       }])
       .config(['$provide', function($provide) {
           $provide.decorator(
               'sldsTableData',
               [
                   '$delegate',
                   function sldsTableDataDecorator($delegate) {
                       var origloadTableData = $delegate.loadTableData;
                       $delegate.loadTableData = function(
                           offset,
                           sldsGroupedTableParams,
                           ngTableParams,
                           cb,
                           failCb
                       ) {
                           console.log('decorated service');
                           return origloadTableData.apply($delegate,arguments);
                       };

                       $delegate.getContext = function(){
                           return 'mlsTable';
                       };
                       
                       return $delegate;
                   }
               ]
           );
       }]);



},{}],3:[function(require,module,exports){
angular.module('mlsHome')
       .controller('mlsHomeController', function($scope, remoteActions,$rootScope,$http, $q, MLSService, MLSFactory) {
           var nsPrefix = $rootScope.nsPrefix || '';
           var baseStringField = nsPrefix + 'StringId__r.' + nsPrefix + 'BaseString__c';
           var ids = [];
           var idsToBeDeleted = [];
           var page = {
               pagesize: 2,
               offsetSize:0,
               curOffsetSize:-1,
               totalSize:0,
               last: {
                   pagesize: 2,
                   offsetSize:0,
                   totalSize:0
               }
           };
           var isDeleteClicked = false;
           var isSaveClicked = false;

           function getMapUrl(payload) {
               var result; 
               result  = payload.search
                      && (payload.filters.length > 0)
                      && true;

           }

           $rootScope.translationRecords = {
               needUpdate: function(){
                   return ids.length > 0;
               },
               needDelete: function(){
                   return idsToBeDeleted.length > 0;
               },
               addToUpdatedRows: function(id){
                   if (id === null) {
                       ids = [];
                   }

                   if (id){
                       ids.push(id);
                   }

                   return ids;
               },
               addToDeleteRows: function(id, flag){
                   if (id && flag){
                       idsToBeDeleted.push(id);
                   }

                   if (!flag) {
                       idsToBeDeleted = _.filter(idsToBeDeleted, function(record){
                           return id !== record;
                       });
                   }

                   return idsToBeDeleted;
               }
           };

           $rootScope.disablePrevButton = function(){
               return !(page.curOffsetSize > 0);
           };

           $rootScope.disableNextButton = function(){
               return !page.offsetSize;
           };

           $rootScope.prevPage = function(cb) {
               if (page.curOffsetSize > 0) {
                   page.paginateAction = true;
                   page.offsetSize = page.curOffsetSize - page.pagesize;
                   page.curOffsetSize = page.curOffsetSize - page.pagesize;
                   page.curOffsetSize = page.curOffsetSize > 0 ? page.curOffsetSize : 0;
                   cb();
               }

           };


           //cb here is sldsgrouped table reload
           $rootScope.nextPage = function(cb) {
               if (page.offsetSize) {
                   page.paginateAction = true;
                   cb();
               }
               return;
           };

           $rootScope.defaultFilters = ['=', 'LIKE %%', 'LIKE %'];


           $rootScope.deleteClicked = function() {
              isDeleteClicked = true;
           };
           $rootScope.saveClicked = function() {
              isSaveClicked = true;
           };
           $scope.mlsTranslationObject = {
               createRequestPayload: function(obj, ngTableParams) {
                   
                   try{
                       var payload = {};
                       
                       if (obj.searchBy && obj.searchBy.value !== '') {
                           payload.searchBy = obj.searchBy.value || '';
                       }
                       

                       payload.filters = MLSFactory.createFiltersPayload(
                           obj.filters,
                           obj.extraFilters
                       );

                       payload.sortBy=MLSFactory.createSortingPayload(
                           ngTableParams.sorting()
                       );

                       //if there are updated records
                       if (isSaveClicked && ids.length) {
                           payload.records = MLSFactory.createUpdatedRecordsPayload(
                               ngTableParams.data,
                               ids
                           );
                           ids=[];
                           isSaveClicked = false;
                       }

                       //if there are items to be deleted
                       if (isDeleteClicked && idsToBeDeleted.length) {
                           payload.id = MLSFactory.createDeleteRecordsPayload(idsToBeDeleted);
                           idsToBeDeleted = [];
                           isDeleteClicked = false;
                       }


                       //this means next or prev page was hit
                       if (page.paginateAction) {
                           payload.pagesize =  "" + (page.pagesize || 0) ;
                           payload.offsetSize = "" + page.offsetSize;
                       }

                       return MLSService
                           .getVlocityAction(payload, page.paginateAction, ngTableParams)
                           .then(function(payload) {
                               payload = angular.fromJson(payload);
                               obj.timeAsOfNow = new Date();
             
                               //revisit and cleanup this code @Hareesh
                               if (page.paginateAction === true) { 
                                   //page.paginateAction = false;
                               }

                               var params =   payload.actions &&
                                              payload.actions.nexttranslation &&
                                              payload.actions.nexttranslation.remote &&
                                              payload.actions.nexttranslation.remote.params;
                               

                               if (params && Object.keys(params)) {
                                   page.curOffsetSize = page.paginateAction ?
                                                        page.offsetSize : -1;
                                   page.offsetSize = params.offsetSize;
                                   page.pagesize = params.pagesize;
                                   page.totalSize = payload.totalSize;
                               }else {
                                   page.curOffsetSize = page.paginateAction ? page.offsetSize :-1;
                                   page.offsetSize = null;
                               }

                               page.paginateAction = false;
                               
                               return (payload.records && payload.records ) || [];
                           });
                       
                       
                   }catch(exception){
                       console.log('something went wrong ', exception);
                       return {};
                   }
               }
           };
           var localeCodeToLabel = {};
           $scope.getLocaleCodeDetails = function() {

            remoteActions.getObjectPicklistsByName(nsPrefix + 'StringTranslation__c')
                        .then(function(response) {
                            var res = angular.fromJson(response);
                            if(res && res[nsPrefix + 'LocaleCode__c']) {
                                var localeCodeList = res[nsPrefix + 'LocaleCode__c'];

                                for (var i = 0; i < localeCodeList.length; i++) {
                                    var locale = localeCodeList[i];
                                    localeCodeToLabel[locale.value] = locale.label;
                                }
                            }
                        });
           }
           $scope.getLocaleCodeDetails();
           $scope.defaultColumns = [
               {
                   field: baseStringField,
                   title: 'MASTER  TEXT',
                   sortable: function(column){
                       return nsPrefix + 'BaseString__c';
                   },
                   getValue: function($scope,row){
                       return row[nsPrefix + 'StringId__r'][nsPrefix + 'BaseString__c'];
                   }
               },
               {
                   field: 'Name',
                   title: 'TRANSLATED TEXT',
                   getValue: function($scope,row) {
                       return '';
                   }
               },
               {
                   field:  nsPrefix + 'LocaleCode__c',
                   title: 'LOCALE',
                   getValue: function($scope, row) {
                        var label = localeCodeToLabel[row[nsPrefix + 'LocaleCode__c']];
                        if(label) {
                            return label;
                        }
                      return row[nsPrefix + 'LocaleCode__c'];
                   }
               }
           ];

           $rootScope.mlsFilterNames = [
               {
                   IsFilterable: true,
                   IsSortable:true,
                   Label:"Translation",
                   Name: nsPrefix + "Translation__c",
                   Type:"TEXTAREA"
               },
               {
                   IsFilterable: true,
                   IsSortable:true,
                   Label:"Locale Code",
                   Name:nsPrefix + "LocaleCode__c",
                   Type:"PICKLIST"
               },
               {
                   IsFilterable: true,
                   IsSortable:true,
                   Label:"Master text",
                   Name:baseStringField,
                   Type:"TEXTAREA"
               }
           ];
           
           
           $scope.rowActions = null;
           
       });

},{}],4:[function(require,module,exports){
angular.module('mlsHome')
       .factory('MLSFactory', function($q, $http, $rootScope){

           function getFilterValue(operator, value) {
               value = value.replace('_', '%5F');

               if (operator === 'LIKE %%') {
                   return '%25' + value + '%25';
               }
               
               if (operator === 'LIKE %') {
                   return value + '%25';
               }
               return value;
           }

           function createFiltersPayload(filters, extraFilters) {
               var results = (filters || [])
                   .concat(extraFilters || [])
                   .map(function (filter) {
                       return{
                           name: filter.name.Name,
                           //operator:filter.operator,
                           value: getFilterValue(filter.operator, filter.value)
                       };
                   }) || [];

               if (!results.length) {
                   return '';
               }

               
               var output = {};
               _.map(results, function(result) {
                   if (output[result.name]){
                       output[result.name] = output[result.name] + "_" + result.value;
                   }else {
                       output[result.name] = result.value;
                   }
               });

               return Object.keys(output).reduce(function(start,key){
                   start = start + key + ":" + output[key] + ",";
                   return start;
               },'');


               /* return results.reduce(function(start, result){
                *     start = start + result.name + ':' + result.operator + ':' + result.value + ',';
                *     return start ;
                * },'');*/
               
           }

           function createSortingPayload(tableSortingRecords){
               var sortingPayload = [];
               if (tableSortingRecords.none) {
                   sortingPayload.push({
                       column: 'Name',
                       value: 'asc'
                   });
               } else if (Object.keys(tableSortingRecords).length > 0) {
                   Object.keys(tableSortingRecords).map(function(key) {
                       sortingPayload.push({
                           column: key,
                           value: tableSortingRecords[key]
                       });
                   });
               }

               if (!sortingPayload.length){
                   return '';
               }

               return sortingPayload.reduce(function(start, data, index) {
                   start = start + data.column + "_" + data.value.toUpperCase();
                   if (index === sortingPayload.length - 1){
                       return start;                       
                   }

                   start = start + ',';
                   return start;
               },'');
               
           }

           function createUpdatedRecordsPayload(recs, ids){
               return (
                   _.filter(recs,
                            function(data) {
                                return _.includes(ids, data.Id);
                            })
                    .map(function(record) {
                        var translationField = nsPrefix + "Translation__c";
                        var localeField = nsPrefix + "LocaleCode__c";
                        var stringField = nsPrefix + "StringId__c";
                        var obj = {};
                        //console.log('record is ' , record);
                        obj['Id']  = record.Id;
                        obj[translationField] = record[translationField];
                        obj[stringField] = record[stringField];
                        obj[localeField] = record[localeField];
                        return obj;
                    })
               );
           }

           function createDeleteRecordsPayload(idsToBeDeleted) {
               return idsToBeDeleted.reduce(function(start, recordId){
                   start = start + recordId + ",";
                   return start;
               },'');
           }

           var nsPrefix = $rootScope.nsPrefix;

           return {
               createFiltersPayload: createFiltersPayload,
               createSortingPayload: createSortingPayload,
               createUpdatedRecordsPayload: createUpdatedRecordsPayload,
               createDeleteRecordsPayload: createDeleteRecordsPayload
           };

       });

},{}],5:[function(require,module,exports){
angular.module('mlsHome')
       .run(function($rootScope, $q, $http){
           $rootScope.nsPrefix = window.nsPrefix; //comes from the mlshome controller
       });

},{}],6:[function(require,module,exports){
angular.module('mlsHome')
       .service('MLSService', ['$q', '$log', 'remoteActions', function($q, $log, remoteActions){
           
           function getVlocityAction(payload, bPaginate, ngTableParams) {
               if (bPaginate) {
                   return remoteActions.doGenericInvoke(
                       "APIHandler",
                       "getStringTranslations",
                       angular.toJson(payload),
                       null
                   );
               }

               if (payload.id && payload.id.length > 0) {
                   return remoteActions.doGenericInvoke(
                       "APIHandler",
                       "deleteStringTranslations",
                       angular.toJson(payload),
                       null
                   ).then(function(resPayload){
                       resPayload = JSON.parse(resPayload);
                       if (resPayload.messages[0].code === "905") {
                           return {
                               records: _.remove(ngTableParams.data, function(data) {
                                   return payload.id.indexOf(data.Id) === -1;
                               })
                           };
                       }
                       $log.error('there was a problem with the deletion');
                   });
               }

               
               if (payload.records &&  payload.records.length > 0) {
                   return remoteActions.doGenericInvoke(
                       "APIHandler",
                       "updateStringTranslations",
                       angular.toJson(payload),
                       null
                   ).then(function(){
                       payload.records = null;
                       return remoteActions.doGenericInvoke(
                           "APIHandler",
                           "getStringTranslations",
                           angular.toJson(payload),
                           null
                       );
                   });
                   
               }

               return remoteActions.doGenericInvoke(
                   "APIHandler",
                   "getStringTranslations",
                   angular.toJson(payload),
                   null
               );

           };

           this.getVlocityAction = getVlocityAction;
       }]);

},{}],7:[function(require,module,exports){
angular.module("mlsHome").run(["$templateCache",function($templateCache){"use strict";$templateCache.put("SldsEditableCellMLS.tpl.html",'<td class="slds-cell-edit" \n    ng-class="{\'slds-cell-error\': vm.isEditing && vm.isValid == false, \n               \'slds-has-error\' : !vm.isEditing && vm.isValid == false,\n               \'slds-is-edited\' : !vm.isEditing && vm.ngModelCtrl.$dirty, \n               \'slds-has-focus\' : !vm.isEditing && vm.focus}"\n    ng-click="vm.startEdit()"\n    ng-focus="vm.focus = true" \n    ng-blur="vm.focus = false"\n    ng-keypress="vm.handleUnfocussedKeyPress($event)"\n    role="gridcell"\n    ng-attr-tabindex="{{vm.isEditing ? -1 : 0}}">\n    <span class="slds-grid slds-grid_align-spread">\n        <span class="slds-truncate" \n              ng-attr-title="{{vm.ngModelCtrl.$viewValue}}"\n              ng-hide="vm.isEditing"\n              ng-bind="vm.ngModelCtrl.$viewValue"></span>\n        <button class="slds-button slds-button_icon slds-cell-edit__button slds-m-left_x-small"\n                ng-hide="vm.isEditing"\n                tabindex="-1">\n            <span class="slds-assistive-text">Edit</span>\n            <slds-button-svg-icon sprite="\'utility\'" \n                                  icon="\'edit\'"\n                                  extra-classes="\'slds-button__icon_hint slds-button__icon_edit\'"></slds-button-svg-icon>\n        </button>\n    </span>\n    <section class="slds-popover slds-popover_edit" \n             role="dialog" \n             ng-if="vm.isEditing"\n             ng-keyup="vm.handleKeyUp($event)">\n        <span tabindex="0"></span>\n        <div class="slds-grid" ng-transclude></div>\n        <span tabindex="0"></span>\n    </section>\n</td>\n'),$templateCache.put("SldsHomeMLS.tpl.html",'<div class="slds-grid slds-grid--vertical slds-grid--vertical-stretch" style="height: 100%; width: 100%">\n  <style>\n    .via-slds.Theme3 .slds-page-header{\n      background: #FFFFFF;\n    }\n    .via-slds.Theme3 .via-slds-home-page {\n      max-height: 100vh;\n    }\n    html, body, .via-slds.Theme4, .via-slds.Theme4d {\n      height: 100%;\n      width: 100%;\n    }\n  </style>\n  <div class="via-slds-home-page slds-col slds-grid slds-grid--vertical slds-grid--vertical-stretch" style="min-height: 0;">\n    <div>\n      <slds-object-home-header\n          label="\'\'"\n          page-title="pageTitle"\n          image-url="imageUrl">\n          <div class="slds-button-space-left">\n            <div class="slds-form-element">\n              <div class="slds-form-element__control slds-input-has-icon  custom-slds-icon--modified">\n                <slds-svg-icon size="\'small\'" extra-classes="\'slds-input__icon slds-icon-text-default slds-m-left--small\'" sprite="\'utility\'" icon="\'search\'"></slds-svg-icon>\n                <input class="slds-input slds-p-left--x-large" autofocus ng-change="onSearchBy(searchParam)" ng-model="searchParam" ng-model-options="{debounce: 1000}"\n                  placeholder="Find in page"></input>\n              </div>\n            </div>\n          </div>\n\n        <div class="slds-button-space-left">\n            <button class="slds-button slds-button--icon-border slds-not-selected"\n                    ng-click="sldsGroupedTableParams.reload()"\n                    id="{{idPrefix}}-refresh-btn"\n                    title="{{::$root.vlocity.getCustomLabel(\'RefreshData\', \'Refresh Data\')}}">\n                <slds-button-svg-icon sprite="\'utility\'" icon="\'refresh\'"></slds-button-svg-icon>\n                <span class="slds-assistive-text">{{::$root.vlocity.getCustomLabel(\'RefreshData\', \'Refresh Data\')}}</span>\n            </button>\n            <button class="slds-button slds-button--icon-border slds-not-selected"\n                    ng-click="$root.prevPage(sldsGroupedTableParams.reload)"\n                    id="{{idPrefix}}-refresh-btn"\n                    ng-disabled="$root.disablePrevButton()"\n                    title="{{::$root.vlocity.getCustomLabel(\'prevPage\', \'prevPage\')}}">\n                <slds-button-svg-icon sprite="\'utility\'" icon="\'chevronleft\'"></slds-button-svg-icon>\n                <span class="slds-assistive-text">{{::$root.vlocity.getCustomLabel(\'prevPage\', \'prevPage\')}}</span>\n            </button>\n            <button class="slds-button slds-button--icon-border slds-not-selected"\n                    ng-click="$root.nextPage(sldsGroupedTableParams.reload)"\n                    id="{{idPrefix}}-refresh-btn"\n                    ng-disabled="$root.disableNextButton()"\n                    title="{{::$root.vlocity.getCustomLabel(\'nextPage\', \'nextPage\')}}">\n                <slds-button-svg-icon sprite="\'utility\'" icon="\'chevronright\'"></slds-button-svg-icon>\n                <span class="slds-assistive-text">{{::$root.vlocity.getCustomLabel(\'nextPage\', \'nextPage\')}}</span>\n            </button>\n          </div>\n          <div class="slds-button-group slds-button-space-left" role="group">\n            <button class="slds-button slds-button--icon-border "\n                    ng-class="{\'slds-is-selected\': viewModel.showFilter, \'slds-not-selected\': !viewModel.showFilter}"\n                    ng-click="toggleFilter()"\n                    id="{{idPrefix}}-toggle-filter-btn"\n                    title="{{::$root.vlocity.getCustomLabel(\'FilterList\', \'Filter List\')}}">\n              <slds-button-svg-icon sprite="\'utility\'" icon="\'filterList\'"></slds-button-svg-icon>\n              <span class="slds-assistive-text">{{::$root.vlocity.getCustomLabel(\'FilterList\', \'Filter List\')}}</span>\n            </button>\n          </div>\n          <div class="slds-button-group" role="group">\n            <button class="slds-button slds-button_brand"\n                    ng-if="$root.translationRecords.needUpdate()"\n                    id="{{idPrefix}}-save-btn"\n                    ng-click="$root.saveClicked(); $parent.sldsGroupedTableParams.reload()"\n                    title="{{::$root.vlocity.getCustomLabel(\'Save\', \'Save\')}}">\n                {{::$root.vlocity.getCustomLabel(\'Save\', \'Save\')}}</button>\n            <button class="slds-button slds-button_brand"\n                    ng-if="$root.translationRecords.needDelete()"\n                    id="{{idPrefix}}-delete-btn"\n                    ng-click="$root.deleteClicked(); $parent.sldsGroupedTableParams.reload()"\n                    title="{{::$root.vlocity.getCustomLabel(\'Delete\', \'Delete\')}}">\n              {{::$root.vlocity.getCustomLabel(\'Delete\', \'Delete\')}}</button>\n            </button>\n\n            <slds-dropdown type="\'button-group\'" content="additionalTableButtons" ng-if="additionalTableButtons.length > 0"\n                            title="{{::$root.vlocity.getCustomLabel(\'AdditionalActions\', \'Additional Actions\')}}"></slds-dropdown>\n          </div>\n      </slds-object-home-header>\n    </div>\n    <div class="slds-col slds-grid slds-grid--vertical-stretch" ng-if="loading">\n      <div ng-include="\'SldsTableStencil.tpl.html\'" class="slds-col"></div>\n    </div>\n    <div class="slds-col slds-grid slds-grid--vertical-stretch" ng-if="!loading && sldsGroupedTableParams" style="min-height: 0">\n      <slds-table class="slds-col slds-grid slds-grid--vertical-stretch hareesh-table-mls"\n                  ng-if="sldsGroupedTableParams.groupBy === false"\n                  slds-grouped-table-params="sldsGroupedTableParams"\n                  template-path="SldsTableMLS.tpl.html"\n                  id-prefix="{{idPrefix}}"></slds-table>\n      <slds-grouped-table class="slds-col slds-grid slds-grid--vertical-stretch"\n                          ng-if="sldsGroupedTableParams.groupBy !== false"\n                          slds-grouped-table-params="sldsGroupedTableParams"\n                          id-prefix="{{idPrefix}}"></slds-grouped-table>\n      <div class="slds-col--rule-left slds-filter-panel" slds-filter-panel ng-show="viewModel.showFilter" show="viewModel.showFilter"\n           filters="filters" names="$root.mlsFilterNames"\n           default-filters="$root.defaultFilters"\n           description="description"></div>\n    </div>\n  </div>\n</div>\n'),$templateCache.put("SldsTableMLS.tpl.html",'<div class="slds-col slds-grid slds-grid--vertical slds-grid--vertical-stretch">\n    <style>\n     .via-slds .slds-table .slds-text-heading--label th.row-action .slds-button {\n         visibility: hidden\n     }\n\n     .via-slds .slds-table {\n         border-collapse: separate;\n     }\n\n     .via-slds .slds-table td:not(.slds-cell-shrink),\n     .via-slds .slds-table th:not(.slds-cell-shrink) {\n         overflow-x: hidden;\n     }\n\n     .via-slds .slds-table .via-table-group-hidden-header tr,\n     .via-slds .slds-table .via-table-group-hidden-header th {\n         padding-top: 0;\n         padding-bottom: 0;\n         display:none ;\n     }\n\n     /* columns should not be resizable */\n     .slds-resizable{\n         pointer-events:none;\n         display:none;\n     }\n    </style>\n    <table class="slds-table slds-table--bordered slds-table--resizable-cols slds-table--fixed-layout via-slds-table-pinned-header slds-table--cell-buffer"\n           ng-table-dynamic="ngTableParams with ::sldsGroupedTableParams.columns" \n           show-group="false" \n           id-prefix="{{::idPrefix}}-grouped-table"\n           data-resizable-columns-id="{{::idPrefix}}-resizable-table-header">\n        <thead>\n            <tr class="slds-text-heading--label" ng-controller="ngTableSorterRowController">\n                <th class="slds-cell-shrink" \n                    ng-if="::(sldsGroupedTableParams.multiselect)" \n                    data-noresize \n                    id="{{::idPrefix}}-group-header-{{$column.id  || $index}}">\n                    <span class="slds-checkbox"\n                          style="opacity:-1"\n                          id="{{::idPrefix}}-group-header-select-all" \n                          title="{{::$root.vlocity.getCustomLabel(\'ToggleSelection\', \'Toggle Selection\')}}">\n                        <input type="checkbox" \n                               name="options" \n                               id="checkbox-317" \n                               ng-model="selected.anySelected" \n                               slds-indeterminate="selected.indeterminate"\n                               ng-change="toggleSelectAll()" />\n                        <label class="slds-checkbox__label" \n                               for="checkbox-317">\n                            <span class="slds-checkbox--faux"></span>\n                            <span class="slds-form-element__label"></span>\n                        </label>\n                    </span>\n                </th>\n                <th scope="col"\n                    ng-repeat="$column in ::$columns" \n                    ng-class="{\'slds-is-sortable\': $column.sortable(this), \'slds-is-sorted slds-is-sorted--asc\' : params.sorting()[$column.sortable(this)]==\'asc\', \'slds-is-sorted slds-is-sorted--desc\' : params.sorting()[$column.sortable(this)]==\'desc\', \'slds-cell-shrink\': $column.shrink}" \n                    id-prefix="idPrefix-grouped-table" \n                    ng-init="template = $column.headerTemplateURL(this)"\n                    ng-click="$column.sortable(this) && sortBy($column, $event)" \n                    class="{{$column.class(this)}} slds-text-title--caps"\n                    id="{{::idPrefix}}-group-header-{{$column.id  || $index}}" \n                    data-resizable-column-id="{{::idPrefix}}-column-{{::$column.id}}"\n                    ng-style="{\'width\': $column.width ? $column.width + \'px\' : \'auto\'}" ng-data-noresize="!$column.resizable">\n                    <div class="slds-truncate" \n                         ng-if="::(!$column.sortable(this))" \n                         ng-bind="::($column.title(this))"></div>\n                    <a href="javascript:void(0)" \n                       class="slds-th__action slds-text-link--reset" \n                       ng-if="::$column.sortable(this)" \n                       id="{{::idPrefix}}-header--{{::$column.id}}-sort"\n                       title="{{::$root.vlocity.getCustomLabel(\'Sort\', \'Sort\')}}">\n                        <span class="slds-truncate" \n                              title="{{::($column.title(this))}}" \n                              ng-bind="::($column.title(this))"></span>\n                        <div class="slds-icon_container">\n                            <slds-svg-icon\n                                sprite="\'utility\'" \n                                size="\'x-small\'" \n                                icon="\'arrowdown\'" \n                                extra-classes="\'slds-icon-text-default slds-is-sortable__icon\'">\n                            </slds-svg-icon>\n                        </div>\n                    </a>\n                </th>\n            </tr>\n        </thead>\n    </table>\n    <div class="slds-col" \n         style="overflow: auto; -webkit-overflow-scrolling: touch">\n        <table class="slds-table slds-table--bordered slds-table--fixed-layout slds-table--cell-buffer"\n               ng-table-dynamic="ngTableParams with ::sldsGroupedTableParams.columns" \n               show-group="false" \n               id-prefix="{{::idPrefix}}-grouped-table"\n               data-resizable-columns-id="{{::idPrefix}}-resizable-table" \n               ng-table-resizable-columns header-holder="{{::idPrefix}}-resizable-table-header">\n            <thead class="via-table-group-hidden-header">\n                <tr class="slds-text-heading--label" \n                    ng-controller="ngTableSorterRowController">\n                    <th class="slds-cell-shrink" \n                        ng-if="::(sldsGroupedTableParams.multiselect)" \n                        data-noresize>\n                    </th>\n                    <th scope="col" \n                        ng-repeat="$column in ::$columns" \n                        ng-init="template = $column.headerTemplateURL(this)" \n                        id="{{::idPrefix}}-header-{{::$column.id}}" \n                        data-resizable-column-id="{{::idPrefix}}-column-{{::$column.id}}"\n                        ng-style="{\'width\': $column.width ? $column.width + \'px\' : \'auto\'}" ng-data-noresize="!$column.resizable">\n                    </th>\n                    <th class="slds-cell-shrink" \n                        data-noresize></th>\n                </tr>\n            </thead>\n\n            <tbody ng-if="!loading">\n                <tr class="slds-hint-parent" \n                    ng-repeat="row in $data" \n                    ng-class="{\'slds-is-selected\': row.selected}" \n                    role="row"\n                    id="{{::idPrefix}}-row-{{::$index}}">\n                    <td class="slds-cell-shrink" \n                        data-label="{{::$root.vlocity.getCustomLabel(\'SelectRow\', \'Select Row\')}}">\n                        <label class="slds-checkbox" \n                               ng-if="::(sldsGroupedTableParams.multiselect)" \n                               id="{{::idPrefix}}-row-{{::$index}}-select-row"\n                               title="{{::$root.vlocity.getCustomLabel(\'SelectRow\', \'Select Row\')}}">\n                            <input type="checkbox" \n                                   name="options" \n                                   ng-model="row.selected" \n                                   ng-change="$root.translationRecords.addToDeleteRows(row.Id,row.selected)" />\n                            <span class="slds-checkbox--faux"></span>\n                            <span class="slds-assistive-text">{{::$root.vlocity.getCustomLabel(\'SelectRow\', \'Select Row\')}}</span>\n                        </label>\n                    </td>\n\n                    <td ng-init="col = $columns[0]" \n                        slds-bind-compiled-html="col.getValue(this, row)" \n                        is-dynamic="::(col.dynamic === true || col.dynamic === \'row\')"\n                        ng-class="::{\'slds-truncate\': !col.shrink, \'slds-cell-shrink\': col.shrink}" \n                        id="{{::idPrefix}}-row-{{::$index}}-{{::col.id}}"></td>\n\n                    <th class="slds-truncate slds-editable-input"\n                        scope="row"\n                        id="{{::idPrefix}}-row-{{::$index}}-{{::$columns[0].id}}" \n                        ng-model="row[$root.nsPrefix + \'Translation__c\']"\n                        template-path="SldsEditableCellMLS.tpl.html"\n                        slds-editable-cell="mls-editable-cell"\n                        is-dynamic="::($columns[0].dynamic === true || $columns[0].dynamic === \'row\')">\n\n                        <textarea \n                            ng-init="$root.translationRecords.addToUpdatedRows(row.Id)"\n                            ng-model="row[$root.nsPrefix + \'Translation__c\']"\n                            class="slds-input"\n                            placeholder="Placeholder Text">\n                        </textarea>\n                        \n                    </th>\n                    <td ng-repeat="col in ::$columns | limitTo: -1" \n                        slds-bind-compiled-html="col.getValue(this, row)" \n                        is-dynamic="::(col.dynamic === true || col.dynamic === \'row\')"\n                        ng-class="::{\'slds-truncate\': !col.shrink, \'slds-cell-shrink\': col.shrink}" \n                        id="{{::idPrefix}}-row-{{::$index}}-{{::col.id}}"></td>\n                    <td class="slds-cell-shrink" \n                        ng-if="::actions">\n                        <slds-dropdown content="::actions" \n                                       ng-if="!row.deleting" \n                                       id-prefix="{{::idPrefix}}-row-{{::$parent.$index}}-{{::$index}}-actions"></slds-dropdown>\n                        <button class="slds-button slds-button--icon-bare" \n                                ng-if="row.deleting">\n                            <slds-button-svg-icon sprite="\'utility\'" \n                                                  icon="\'spinner\'"></slds-button-svg-icon>\n                            <span class="slds-assistive-text">{{::$root.vlocity.getCustomLabel(\'Deleting\', \'Deleting\')}}</span>\n                        </button>\n                    </td>\n                </tr>\n            </tbody>\n            <tbody>\n                <tr ng-if="!loading && !maxLoad">\n                    <td class="slds-truncate" \n                        id="via-slds-loadingSpinnerRow"\n                        colspan="{{::$columns.length + 1}}">\n                        &nbsp;\n                        <div class="slds-spinner_container" \n                             style="z-index: 5">\n                            <div class="slds-spinner--brand slds-spinner slds-spinner--small" \n                                 aria-hidden="false" \n                                 role="alert">\n                                <div class="slds-spinner__dot-a"></div>\n                                <div class="slds-spinner__dot-b"></div>\n                            </div>\n                        </div>\n                    </td>\n                </tr>\n                <tr ng-if="loading">\n                    <td colspan="{{::$columns.length + 1}}" \n                        style="width: 100%; height: 400px">\n                        <div class="slds-spinner_container"\n                             style="z-index: 5">\n                            <div class="slds-spinner--brand slds-spinner slds-spinner--large" \n                                 aria-hidden="false" \n                                 role="alert">\n                                <div class="slds-spinner__dot-a"></div>\n                                <div class="slds-spinner__dot-b"></div>\n                            </div>\n                        </div>\n                    </td>\n                </tr>\n            </tbody>\n        </table>\n    </div>\n</div>\n')}]);
},{}]},{},[1]);

})();