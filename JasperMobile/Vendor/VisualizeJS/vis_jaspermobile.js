!function(global){function isArray(arr){return"[object Array]"===Object.prototype.toString.call(arr)}function foreach(arr,handler){if(isArray(arr))for(var i=0;i<arr.length;i++)handler(arr[i]);else handler(arr)}function D(fn){var status="pending",doneFuncs=[],failFuncs=[],progressFuncs=[],resultArgs=null,promise={done:function(){for(var i=0;i<arguments.length;i++)if(arguments[i])if(isArray(arguments[i]))for(var arr=arguments[i],j=0;j<arr.length;j++)"resolved"===status&&arr[j].apply(this,resultArgs),doneFuncs.push(arr[j]);else"resolved"===status&&arguments[i].apply(this,resultArgs),doneFuncs.push(arguments[i]);return this},fail:function(){for(var i=0;i<arguments.length;i++)if(arguments[i])if(isArray(arguments[i]))for(var arr=arguments[i],j=0;j<arr.length;j++)"rejected"===status&&arr[j].apply(this,resultArgs),failFuncs.push(arr[j]);else"rejected"===status&&arguments[i].apply(this,resultArgs),failFuncs.push(arguments[i]);return this},always:function(){return this.done.apply(this,arguments).fail.apply(this,arguments)},progress:function(){for(var i=0;i<arguments.length;i++)if(arguments[i])if(isArray(arguments[i]))for(var arr=arguments[i],j=0;j<arr.length;j++)"pending"===status&&progressFuncs.push(arr[j]);else"pending"===status&&progressFuncs.push(arguments[i]);return this},then:function(){arguments.length>1&&arguments[1]&&this.fail(arguments[1]),arguments.length>0&&arguments[0]&&this.done(arguments[0]),arguments.length>2&&arguments[2]&&this.progress(arguments[2])},promise:function(obj){if(null==obj)return promise;for(var i in promise)obj[i]=promise[i];return obj},state:function(){return status},debug:function(){console.log("[debug]",doneFuncs,failFuncs,status)},isRejected:function(){return"rejected"===status},isResolved:function(){return"resolved"===status},pipe:function(done,fail){return D(function(def){foreach(done,function(func){"function"==typeof func?deferred.done(function(){var returnval=func.apply(this,arguments);returnval&&"function"==typeof returnval?returnval.promise().then(def.resolve,def.reject,def.notify):def.resolve(returnval)}):deferred.done(def.resolve)}),foreach(fail,function(func){"function"==typeof func?deferred.fail(function(){var returnval=func.apply(this,arguments);returnval&&"function"==typeof returnval?returnval.promise().then(def.resolve,def.reject,def.notify):def.reject(returnval)}):deferred.fail(def.reject)})}).promise()}},deferred={resolveWith:function(context){if("pending"===status){status="resolved";for(var args=resultArgs=arguments.length>1?arguments[1]:[],i=0;i<doneFuncs.length;i++)doneFuncs[i].apply(context,args)}return this},rejectWith:function(context){if("pending"===status){status="rejected";for(var args=resultArgs=arguments.length>1?arguments[1]:[],i=0;i<failFuncs.length;i++)failFuncs[i].apply(context,args)}return this},notifyWith:function(context){if("pending"===status)for(var args=resultArgs=arguments.length>1?arguments[1]:[],i=0;i<progressFuncs.length;i++)progressFuncs[i].apply(context,args);return this},resolve:function(){return this.resolveWith(this,arguments)},reject:function(){return this.rejectWith(this,arguments)},notify:function(){return this.notifyWith(this,arguments)}},obj=promise.promise(deferred);return fn&&fn.apply(obj,[obj]),obj}D.when=function(){if(arguments.length<2){var obj=arguments.length?arguments[0]:void 0;return obj&&"function"==typeof obj.isResolved&&"function"==typeof obj.isRejected?obj.promise():D().resolve(obj).promise()}return function(args){for(var df=D(),size=args.length,done=0,rp=new Array(size),i=0;i<args.length;i++)!function(j){var obj=null;args[j].done?args[j].done(function(){rp[j]=arguments.length<2?arguments[0]:arguments,++done==size&&df.resolve.apply(df,rp)}).fail(function(){df.reject(arguments)}):(obj=args[j],args[j]=new Deferred,args[j].done(function(){rp[j]=arguments.length<2?arguments[0]:arguments,++done==size&&df.resolve.apply(df,rp)}).fail(function(){df.reject(arguments)}).resolve(obj))}(i);return df.promise()}(arguments)},global.Deferred=D}(window);

var JasperMobile = {
    Report : {},
    Dashboard : {},
    Callback: {
        Queue : {
            queue : [],
            dispatchTimeInterval : null,
            startExecute : function() {
                if (!this.dispatchTimeInterval) {
                    this.dispatchTimeInterval = window.setInterval(JasperMobile.Callback.Queue.execute, 200);
                }
            },
            execute: function() {
                if(JasperMobile.Callback.Queue.queue.length > 0) {
                    var callback = JasperMobile.Callback.Queue.queue.shift();
                    callback();
                } else {
                    window.clearInterval(JasperMobile.Callback.Queue.dispatchTimeInterval);
                    JasperMobile.Callback.Queue.dispatchTimeInterval = null;
                }
            },
            add : function(callback) {
                this.queue.push(callback);
                this.startExecute();
            }
        },
        createCallback: function(params) {
            var callback = "http://jaspermobile.callback/json&&" + JSON.stringify(params);
            this.Queue.add(function() {
                window.location.href = callback;
            })
        },
        onScriptLoaded : function() {
            this.createCallback(
                {
                    "command" : "DOMContentLoaded",
                    "parameters" : {}
                }
            );
        },
        log : function(message) {
            this.createCallback(
                {
                    "command" : "logging",
                    "parameters" : {
                        "message" : message
                    }
                }
            );
        }
    },
    Helper : {
        collectReportParams: function (link) {
            var isValueNotArray, key, params;
            params = {};
            for (key in link.parameters) {
                if (key !== '_report') {
                    isValueNotArray = Object.prototype.toString.call(link.parameters[key]) !== '[object Array]';
                    params[key] = isValueNotArray ? [link.parameters[key]] : link.parameters[key];
                }
            }
            return params;
        },
        updateViewPortScale: function (scale) {
            var viewPortContent = 'initial-scale='+ scale + ', width=device-width, maximum-scale=2.0, user-scalable=yes';
            var viewport = document.querySelector("meta[name=viewport]");
            if (!viewport) {
                var viewport=document.createElement('meta');
                viewport.name = "viewport";
                viewport.content = viewPortContent;
                document.head.appendChild(viewport);
            } else {
                viewport.setAttribute('content', viewPortContent);
            }
        },
        addScript: function(scriptURL, success, error) {
            var isScriptAlreadyLoaded = false;
            var allScripts = document.head.getElementsByTagName("script");

            for(var i=0; i < allScripts.length; i++) {
                var script = allScripts[i];
                if (script.src === scriptURL) {
                    isScriptAlreadyLoaded = true;
                    success();
                    break;
                }
            }
            if (!isScriptAlreadyLoaded) {
                var scriptTag = document.createElement('script');
                scriptTag.src = scriptURL;
                scriptTag.onload = function() {
                    success();
                };
                document.head.appendChild(scriptTag);
            }
        },
        loadScripts: function(parameters) {
            var scriptURLs = parameters["scriptURLs"];
            var callbacksCount = scriptURLs.length;
            for (var i = 0; i < scriptURLs.length; i++) {
                var scriptURL = scriptURLs[i];
                (function(scriptURL) {
                    JasperMobile.Helper.addScript(scriptURL, function() {
                        if (--callbacksCount == 0) {
                            JasperMobile.Callback.Callbacks.successCallback("JasperMobile.Helper.loadScripts", {});
                        }
                    }, null);
                })(scriptURL);
            }
        },
        loadScript: function(parameters) {
            var scriptURL = parameters["scriptURL"];
            JasperMobile.Helper.addScript(scriptURL, function() {
                JasperMobile.Callback.Callbacks.successCallback("JasperMobile.Helper.loadScript", {
                    "params" : {
                        "script_path" : scriptURL
                    }
                });
            }, null);
        }
    }
};

// Callbacks
JasperMobile.Callback.Listeners = {
    listener: function(listener, parameters) {
        JasperMobile.Callback.createCallback(
            {
                "command" : listener,
                "parameters" : parameters
            }
        );
    }
};

JasperMobile.Callback.Callbacks = {
    successCompleted: function(command, parameters) {
        JasperMobile.Callback.createCallback(
            {
                "command" : command,
                "parameters" : parameters
            }
        );
    },
    failedCompleted: function(command, parameters) {
        JasperMobile.Callback.createCallback(
            {
                "command" : command,
                "parameters" : parameters
            }
        );
    },
    successCallback: function(callback, parameters) {
        JasperMobile.Callback.createCallback(
            {
                "command" : callback,
                "parameters" : parameters
            }
        );
    },
    failedCallback: function(callback, parameters) {
        JasperMobile.Callback.createCallback(
            {
                "command" : callback,
                "parameters" : parameters
            }
        );
    }
};

JasperMobile.Report = {
    REST      : {},
    VISUALIZE : {},
    // TODO: Replace 'API' with 'VISUALIZE'
    API       : {}
};

// REST Reports
JasperMobile.Report.REST.API = {
    injectContent: function(contentObject) {
        var content = contentObject["HTMLString"];
        var div = document.getElementById('container');

        if (div == null) {
            JasperMobile.Callback.Callbacks.failedCallback("JasperMobile.Report.REST.API.injectContent", {
                "error" : JSON.stringify({
                    "code"    : "internal.error", // TODO: need error codes?
                    "message" : "No container"
                })
            });
            return;
        }

        div.innerHTML = content;

        if (content == "") {
            JasperMobile.Callback.log("clear content");
        } else {
            // setup scaling
            var childs = document.getElementById('container').childNodes;
            var table = undefined;
            for (var i = 0; i < childs.length; i++) {
                var child = childs[i];
                // TODO: investigate other cases
                if (child.nodeName == "TABLE") {
                    table = child;
                    break;
                }
            }

            if (table != undefined) {
                table.style.transform = "scale(" + innerWidth / parseInt(table.style.width) + ")";
                table.style.transformOrigin = "0% 0%";
            }
        }
        JasperMobile.Callback.Callbacks.successCallback("JasperMobile.Report.REST.API.injectContent", {});
    },
    verifyEnvironmentIsReady: function() {
        JasperMobile.Callback.Callbacks.successCompleted("JasperMobile.Report.REST.API.verifyEnvironmentIsReady", {
            "isReady" : document.getElementById("container") != null
        });
    },
    renderHighcharts: function(parameters) {
        var scripts = parameters["scripts"];
        var isElasticChart = parameters["isElasticChart"];

        JasperMobile.Report.REST.API.chartParams = parameters;

        var script;
        var functionName;
        var chartParams;

        if (isElasticChart == "true") {
            script = scripts[0];
            functionName = script.scriptName.trim();
            chartParams = script.scriptParams;

            var containerWidth = document.getElementById("container").offsetWidth;
            var containerHeight = document.getElementById("container").offsetHeight;

            // Update chart size
            var chartDimensions = chartParams.chartDimensions;
            chartDimensions.width = containerWidth;
            chartDimensions.height = containerHeight;

            // set new chart size
            chartParams.chartDimensions = chartDimensions;

            // run script
            window[functionName](chartParams);
        } else {
            for(var i=0; i < scripts.length; i++) {
                script = scripts[i];
                functionName = script.scriptName.trim();
                chartParams = script.scriptParams;
                window[functionName](chartParams);
            }
        }
        JasperMobile.Callback.Callbacks.successCompleted("JasperMobile.Report.REST.API.renderHighcharts", {});
    },
    executeScripts: function(parameters) {
        var scripts = parameters["scripts"];
        for (var i = 0; i < scripts.length; i++) {
            var script = scripts[i];
            eval(script);
        }
        JasperMobile.Callback.Callbacks.successCompleted("JasperMobile.Report.REST.API.executeScripts", {});
    },
    addHyperlinks: function(hyperlinks) {
        var allSpans = document.getElementsByTagName("span");
        for (var i = 0; i < hyperlinks.length; i++) {
            var hyperlink = hyperlinks[i];
            (function(hyperlink) {
                for (var j=0; j < allSpans.length; j++) {
                    var span = allSpans[j];
                    if (hyperlink.tooltip == span.title) {
                        // add click listener
                        span.addEventListener("click", function() {
                            console.log("click " + hyperlink.id);
                            JasperMobile.Callback.Listeners.listener("JasperMobile.listener.hyperlink", {
                                "type" : hyperlink.type,
                                "params" : hyperlink.params
                            });
                        });
                    }
                    //console.log("span: " + span.title);
                }
            })(hyperlink);
        }
    },
    applyZoomForReport: function() {
        var tableNode = document.getElementsByClassName("jrPage")[0];
        if (tableNode.nodeName == "TABLE") {
            document.body.innerHTML = "<div id='containter'></div>";
            var container = document.getElementById("containter");
            container.appendChild(tableNode);
            var table = tableNode;
            table.style.transform = "scale(" + innerWidth / parseInt(table.style.width) + ")";
            table.style.transformOrigin = "50% 0%";
            JasperMobile.Callback.Callbacks.successCallback("JasperMobile.Report.REST.API.applyZoomForReport", {});
        } else {
            JasperMobile.Callback.Callbacks.failedCallback("JasperMobile.Report.REST.API.applyZoomForReport", {
                "error" : JSON.stringify({
                    "code"    : "internal.error", // TODO: need error codes?
                    "message" : "No table with class 'jrPage'."
                })
            });
        }
    }
};

// VIZ Reports
JasperMobile.Report.API = {
    report: null,
    runReport: function(params) {
        var successFn = function(status) {
            JasperMobile.Callback.Callbacks.successCompleted("JasperMobile.Report.API.runReport", {
                "status" : status,
                "pages" : JasperMobile.Report.API.report.data().totalPages
            });
        };
        var errorFn = function(error) {
            JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Report.API.runReport", {
                "error" : JSON.stringify({
                    "code" : error.errorCode,
                    "message" : error.message
                })
            });
        };
        var events = {
            reportCompleted: function(status) {
                JasperMobile.Callback.Callbacks.successCallback("JasperMobile.Report.API.run.reportCompleted", {
                    "status" : status,
                    "pages" : JasperMobile.Report.API.report.data().totalPages,
                });
            },
            changePagesState: function(page) {
                JasperMobile.Callback.log("Event: changePagesState");
                JasperMobile.Callback.Callbacks.successCallback("JasperMobile.Report.API.run.changePagesState", {
                    "page" : page
                });
            }
        };
        var linkOptionsEventsClick = function(event, link){
            var type = link.type;

            switch (type) {
                case "ReportExecution": {
                    var data = {
                        resource: link.parameters._report,
                        params: JasperMobile.Helper.collectReportParams(link)
                    };
                    var dataString = JSON.stringify(data);
                    JasperMobile.Callback.log("Event: linkOption - ReportExecution");
                    JasperMobile.Callback.Callbacks.successCallback("JasperMobile.Report.API.run.linkOptions.events.ReportExecution", {
                        "data" : dataString
                    });
                    break;
                }
                case "LocalAnchor": {
                    report
                        .pages({
                            anchor: link.anchor
                        })
                        .run()
                        .fail(function(error) {
                            JasperMobile.Callback.log(error);
                        });
                    break;
                }
                case "LocalPage": {
                    report.pages(link.pages)
                        .run()
                        .fail(function(error) {
                            JasperMobile.Callback.log(error);
                        })
                        .done(function() {
                            JasperMobile.Callback.Callbacks.successCallback("JasperMobile.Report.API.run.linkOptions.events.LocalPage", {
                                "page" : link.pages
                            });
                        });
                    break;
                }
                case "Reference": {
                    var href = link.href;
                    JasperMobile.Callback.Callbacks.successCallback("JasperMobile.Report.API.run.linkOptions.events.Reference", {
                        "location" : href
                    });
                    break;
                }
                default: {
                    defaultHandler.call(this);
                }
            }
        };

        var reportStruct = {
            resource: params["uri"],
            params: params["params"],
            pages: params["pages"],
            scale: "width",
            container: "#container",
            success: successFn,
            error: errorFn,
            events: events,
            linkOptions: {
                events: {
                    click : linkOptionsEventsClick
                }
            }
        };
        var auth = {};

        if (params["is_for_6_0"]) {
            auth = {
                auth: {
                    loginFn: function(properties, request) {
                        return (new Deferred()).resolve();
                    }
                }
            };
        } else {
            reportStruct.chart = {
                animation : false,
                zoom : false
            };
        }

        var runFn = function (v) {
            // save link for reportObject
            JasperMobile.Report.API.report = v.report(reportStruct);
        };
        visualize(auth, runFn, errorFn);
    },
    cancel: function() {
        if (JasperMobile.Report.API.report) {
            JasperMobile.Report.API.report.cancel()
                .done(function () {
                    JasperMobile.Callback.log("success cancel");
                })
                .fail(function (error) {
                    JasperMobile.Callback.log("failed cancel with error: " + error);
                });
        } else {
            JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Report.API.cancel", {
                "error": JSON.stringify({
                    "code" : "visualize.error",
                    "message" : "JasperMobile.Report.API.report == nil"
                })
            });
        }
    },
    refresh: function() {
        if (JasperMobile.Report.API.report) {
            JasperMobile.Report.API.report.refresh()
                .done( function(status) {
                        JasperMobile.Callback.Callbacks.successCompleted("JasperMobile.Report.API.refresh", {
                            "status": status,
                            "pages": JasperMobile.Report.API.report.data().totalPages
                        });
                }).fail( function(error) {
                    JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Report.API.refresh", {
                        "error": JSON.stringify({
                            "code" : error.errorCode,
                            "message" : error.message
                        })
                    });
                });
        } else {
            JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Report.API.refresh", {
                "error": JSON.stringify({
                    "code" : "visualize.error",
                    "message" : "JasperMobile.Report.API.report == nil"
                })
            });
        }
    },
    applyReportParams: function(params) {
        if (JasperMobile.Report.API.report) {
            JasperMobile.Report.API.report.params(params).run()
                .done(function (reportData) {
                    JasperMobile.Callback.Callbacks.successCompleted("JasperMobile.Report.API.applyReportParams", {
                        "pages": reportData.totalPages,
                    });
                })
                .fail(function (error) {
                    JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Report.API.applyReportParams", {
                        "error": JSON.stringify({
                            "code" : error.errorCode,
                            "message" : error.message
                        })
                    });
                });
        } else {
            JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Report.API.applyReportParams", {
                "error": JSON.stringify({
                    "code" : "visualize.error",
                    "message" : "JasperMobile.Report.API.report == nil"
                })
            });
        }
    },
    selectPage: function(parameters) {
        var page = parameters["pageNumber"];
        if (JasperMobile.Report.API.report) {
            JasperMobile.Report.API.report.pages(page).run()
                .done(function (reportData) {
                    JasperMobile.Callback.Callbacks.successCompleted("JasperMobile.Report.API.selectPage", {
                        "page": parseInt(JasperMobile.Report.API.report.pages())
                    });
                })
                .fail(function (error) {
                    JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Report.API.selectPage", {
                        "error": JSON.stringify({
                            "code" : error.errorCode,
                            "message" : error.message
                        })
                    });
                });
        } else {
            JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Report.API.selectPage", {
                "error": JSON.stringify({
                    "code" : "visualize.error",
                    "message" : "JasperMobile.Report.API.report == nil"
                })
            });
        }
    },
    exportReport: function(format) {
        if (JasperMobile.Report.API.report) {
            JasperMobile.Report.API.report.export({
                outputFormat: format
            }).done(function (link) {
                JasperMobile.Callback.Callbacks.successCompleted("JasperMobile.Report.API.run", {
                    "link" : link.href
                });
            });
        } else {
            JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Report.API.exportReport", {
                "error": JSON.stringify({
                    "code" : "visualize.error",
                    "message" : "JasperMobile.Report.API.report == nil"
                })
            });
        }
    },
    destroyReport: function() {
        if (JasperMobile.Report.API.report) {
            JasperMobile.Report.API.report.destroy()
                .done(function() {
                    JasperMobile.Callback.Callbacks.successCompleted("JasperMobile.Report.API.destroyReport", {});
                })
                .fail(function(error) {
                    JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Report.API.destroyReport", {
                        "error" : JSON.stringify({
                            "code" : error.errorCode,
                            "message" : error.message
                        })
                    });
                });
        } else {
            JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Report.API.destroyReport", {
                "error": JSON.stringify({
                    "code" : "visualize.error",
                    "message" : "JasperMobile.Report.API.report == nil"
                })
            });
        }
    }
};

// VIZ Dashboards
JasperMobile.Dashboard.API = {
    dashboardObject: {},
    refreshedDashboardObject: {},
    canceledDashboardObject: {},
    dashboardFunction: {},
    selectedDashlet: {}, // DOM element
    selectedComponent: {}, // Model element
    runDashboard: function(params) {
        var successFn = function() {

            setTimeout(function(){
                var data = JasperMobile.Dashboard.API.dashboardObject.data();
                JasperMobile.Callback.Callbacks.successCompleted("JasperMobile.Dashboard.API.runDashboard", {
                    "components" : data.components,
                    "params" : data.parameters
                });
                if (data.components) {
                    JasperMobile.Dashboard.API._configureComponents(data.components);
                }
                JasperMobile.Dashboard.API._defineComponentsClickEvent();
                JasperMobile.Dashboard.API._setupFiltersApperance();
            }, 6000);

        };
        var errorFn = function(error) {
            JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Dashboard.API.runDashboard", {
                "error" : JSON.stringify({
                    "code" : error.errorCode,
                    "message" : error.message
                })
            });
        };
        var dashboardStruct = {
            resource: params["uri"],
            container: "#container",
            linkOptions: {
                events: {
                    click: function(event, link, defaultHandler) {
                        var type = link.type;
                        JasperMobile.Callback.log("link type: " + type);

                        switch (type) {
                            case "ReportExecution": {
                                var data = {
                                    resource: link.parameters._report,
                                    params: JasperMobile.Helper.collectReportParams(link)
                                };
                                var dataString = JSON.stringify(data);
                                JasperMobile.Callback.Callbacks.successCallback("JasperMobile.Dashboard.API.run.linkOptions.events.ReportExecution", {
                                    "data" : dataString
                                });
                                break;
                            }
                            case "LocalAnchor": {
                                defaultHandler.call();
                                break;
                            }
                            case "LocalPage": {
                                defaultHandler.call();
                                break;
                            }
                            case "Reference": {
                                var href = link.href;
                                JasperMobile.Callback.Callbacks.successCallback("JasperMobile.Dashboard.API.run.linkOptions.events.Reference", {
                                    "location" : href
                                });
                                break;
                            }
                            case "AdHocExecution":
                                defaultHandler.call();
                                JasperMobile.Callback.Callbacks.successCallback("JasperMobile.Dashboard.API.run.linkOptions.events.AdHocExecution", {});
                                break;
                            default: {
                                defaultHandler.call();
                            }
                        }
                    }
                }
            },
            success: successFn,
            error: errorFn
        };
        var auth = {};

        if (params["is_for_6_0"]) {
            auth = {
                auth: {
                    loginFn: function(properties, request) {
                        return (new Deferred()).resolve();
                    }
                }
            };
        } else {
            dashboardStruct.report =  {
                chart: {
                    animation: false,
                        zoom: false
                }
            };
        }

        var dashboardFn = function (v) {
            // save link for dashboardObject
            JasperMobile.Dashboard.API.dashboardFunction = v.dashboard;
            JasperMobile.Dashboard.API.dashboardObject = JasperMobile.Dashboard.API.dashboardFunction(dashboardStruct);
        };

        visualize(auth, dashboardFn, errorFn);
    },
    getDashboardParameters: function() {
        var data = JasperMobile.Dashboard.API.dashboardObject.data();
        JasperMobile.Callback.Callbacks.successCompleted("JasperMobile.Dashboard.API.getDashboardParameters", {
            "components" : data.components,
            "params" : data.parameters
        });
    },
    minimizeDashlet: function(parameters) {
        var dashletId = parameters["identifier"];
        if (dashletId != "null") {
            JasperMobile.Dashboard.API.dashboardObject.updateComponent(dashletId, {
                maximized: false,
                interactive: false
            }).done(function() {
                JasperMobile.Callback.Callbacks.successCompleted("JasperMobile.Dashboard.API.minimizeDashlet", {
                    "component" : dashletId
                });
            }).fail(function(error) {
                JasperMobile.Callback.log("failed refresh with error: " + error);
                JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Dashboard.API.minimizeDashlet", {
                    "error" : JSON.stringify({
                        "code" : error.errorCode,
                        "message" : error.message
                    })
                });
            });
        } else {
            // TODO: need this?
            //this._showDashlets();

            // stop showing buttons for changing chart type.
            var chartWrappers = document.querySelectorAll('.show_chartTypeSelector_wrapper');
            for (var i = 0; i < chartWrappers.length; ++i) {
                chartWrappers[i].style.display = 'none';
            }

            JasperMobile.Dashboard.API.selectedDashlet.classList.remove('originalDashletInScaledCanvas');

            JasperMobile.Dashboard.API.dashboardObject.updateComponent(JasperMobile.Dashboard.API.selectedComponent.id, {
                maximized: false,
                interactive: false
            }, function() {
                JasperMobile.Dashboard.API.selectedDashlet = {};
                JasperMobile.Dashboard.API.selectedComponent = {};
                // TODO: need add callbacks?
            }, function(error) {
                JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Dashboard.API.minimizeDashlet", {
                    "error" : JSON.stringify({
                        "code" : error.errorCode,
                        "message" : error.message
                    })
                });
            });
        }
    },
    maximizeDashlet: function(parameters) {
        var dashletId = parameters["identifier"];
        if (dashletId != "null") {
            JasperMobile.Dashboard.API.dashboardObject.updateComponent(dashletId, {
                maximized: true,
                interactive: true
            }).done(function() {
                JasperMobile.Callback.Callbacks.successCompleted("JasperMobile.Dashboard.API.maximizeDashlet", {
                    "component" : dashletId
                });
            }).fail(function(error) {
                JasperMobile.Callback.log("failed refresh with error: " + error);
                JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Dashboard.API.maximizeDashlet", {
                    "error" : JSON.stringify({
                        "code" : error.errorCode,
                        "message" : error.message
                    })
                });
            });
        } else {
            JasperMobile.Callback.log("Try maximize dashlet without 'id'");
        }
    },
    refresh: function() {
        JasperMobile.Callback.log("start refresh");
        JasperMobile.Callback.log("dashboard object: " + JasperMobile.Dashboard.API.dashboardObject);
        JasperMobile.Dashboard.API.refreshedDashboardObject = JasperMobile.Dashboard.API.dashboardObject.refresh()
            .done(function() {
                var data = JasperMobile.Dashboard.API.dashboardObject.data();
                JasperMobile.Callback.Callbacks.successCompleted("JasperMobile.Dashboard.API.refresh", {
                    "components" : data.components,
                    "params" : data.parameters
                });
            })
            .fail(function(error) {
                JasperMobile.Callback.log("failed refresh with error: " + error);
                JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Dashboard.API.refresh", {
                    "error" : JSON.stringify({
                        "code" : error.errorCode,
                        "message" : error.message
                    })
                });
            });
        setTimeout(function() {
            JasperMobile.Callback.log("state: " + JasperMobile.Dashboard.API.refreshedDashboardObject.state());
            if (JasperMobile.Dashboard.API.refreshedDashboardObject.state() === "pending") {
                JasperMobile.Dashboard.API.run({"uri" : JasperMobile.Dashboard.API.dashboardObject.properties().resource});
            }
        }, 20000);
    },
    cancel: function() {
        JasperMobile.Callback.log("start cancel");
        JasperMobile.Callback.log("dashboard object: " + JasperMobile.Dashboard.API.dashboardObject);
        JasperMobile.Dashboard.API.canceledDashboardObject = JasperMobile.Dashboard.API.dashboardObject.cancel()
            .done(function() {
                JasperMobile.Callback.log("success cancel");
                JasperMobile.Callback.Callbacks.successCompleted("JasperMobile.Dashboard.API.cancel", {});
            })
            .fail(function(error) {
                JasperMobile.Callback.log("failed cancel with error: " + error);
                JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Dashboard.API.cancel", {
                    "error" : JSON.stringify({
                        "code" : error.errorCode,
                        "message" : error.message
                    })
                });
            });
    },
    refreshDashlet: function() {
        JasperMobile.Callback.log("start refresh component");
        JasperMobile.Callback.log("dashboard object: " + JasperMobile.Dashboard.API.dashboardObject);
        JasperMobile.Dashboard.API.refreshedDashboardObject = JasperMobile.Dashboard.API.dashboardObject.refresh(JasperMobile.Dashboard.API.selectedComponent.id)
            .done(function() {
                JasperMobile.Callback.log("success refresh");
                var data = JasperMobile.Dashboard.API.dashboardObject.data();
                JasperMobile.Callback.Callbacks.successCompleted("JasperMobile.Dashboard.API.refreshDashlet", {
                    "components" : data.components,
                    "params" : data.parameters
                });
            })
            .fail(function(error) {
                JasperMobile.Callback.log("failed refresh dashlet with error: " + error);
                JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Dashboard.API.refreshDashlet", {
                    "error" : JSON.stringify({
                        "code" : error.errorCode,
                        "message" : error.message
                    })
                });
            });
        setTimeout(function() {
            JasperMobile.Callback.log("state: " + JasperMobile.Dashboard.API.refreshedDashboardObject.state());
            if (JasperMobile.Dashboard.API.refreshedDashboardObject.state() === "pending") {
                JasperMobile.Dashboard.API.run({"uri" : JasperMobile.Dashboard.API.dashboardObject.properties().resource});
            }
        }, 20000);
    },
    applyParams: function(parameters) {

        JasperMobile.Dashboard.API.dashboardObject.params(parameters).run()
            .done(function() {
                var data = JasperMobile.Dashboard.API.dashboardObject.data();
                JasperMobile.Callback.Callbacks.successCompleted("JasperMobile.Dashboard.API.applyParams", {
                    "components" : data.components,
                    "params" : data.parameters
                });
            })
            .fail(function(error) {
                JasperMobile.Callback.log("failed apply");
                JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Dashboard.API.applyParams", {
                    "error" : JSON.stringify({
                        "code" : error.errorCode,
                        "message" : error.message
                    })
                });
            });
    },
    destroy: function() {
        if (JasperMobile.Dashboard.API.dashboardObject) {
            JasperMobile.Dashboard.API.dashboardObject.destroy()
                .done(function() {
                    JasperMobile.Callback.Callbacks.successCompleted("JasperMobile.Dashboard.API.destroy", {});
                })
                .fail(function(error) {
                    JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Dashboard.API.destroy", {
                        "error" : JSON.stringify({
                            "code" : error.errorCode,
                            "message" : error.message
                        })
                    });
                });
        } else {
            JasperMobile.Callback.Callbacks.failedCompleted("JasperMobile.Dashboard.API.destroy", {
                "error": JSON.stringify({
                    "code" : "visualize.error",
                    "message" : "JasperMobile.Dashboard.API.dashboardObject == nil"
                })
            });
        }
    },
    _configureComponents: function(components) {
        components.forEach( function(component) {
            if (component.type !== 'inputControl') {
                JasperMobile.Dashboard.API.dashboardObject.updateComponent(component.id, {
                    interactive: false,
                    toolbar: false
                });
            }
        });
    },
    _defineComponentsClickEvent: function() {
        var dashboardId = JasperMobile.Dashboard.API.dashboardFunction.componentIdDomAttribute;
        var dashlets = JasperMobile.Dashboard.API._getDashlets(dashboardId); // DOM elements
        for (var i = 0; i < dashlets.length; ++i) {
            var parentElement = dashlets[i].parentElement;
            // set onClick listener for parent of dashlet
            parentElement.onclick = function(event) {
                JasperMobile.Dashboard.API.selectedDashlet = this;
                var targetClass = event.target.className;
                if (targetClass !== 'overlay') {
                    return;
                }

                // start showing buttons for changing chart type.
                var chartWrappers = document.querySelectorAll('.show_chartTypeSelector_wrapper');
                for (var i = 0; i < chartWrappers.length; ++i) {
                    chartWrappers[i].style.display = 'block';
                }

                var component, id;
                id = this.getAttribute(dashboardId);
                component = JasperMobile.Dashboard.API._getComponentById(id); // Model object

                // TODO: need this?
                //self._hideDashlets(dashboardId, dashlet);

                if (component && !component.maximized) {
                    JasperMobile.Callback.Callbacks.successCallback("JasperMobile.Dashboard.API.events.dashlet.willMaximize", {
                        "component" : component
                    });
                    JasperMobile.Dashboard.API.selectedDashlet.className += "originalDashletInScaledCanvas";
                    JasperMobile.Dashboard.API.dashboardObject.updateComponent(id, {
                        maximized: true,
                        interactive: true
                    }, function() {
                        JasperMobile.Dashboard.API.selectedComponent = component;
                        JasperMobile.Callback.Callbacks.successCallback("JasperMobile.Dashboard.API.events.dashlet.didMaximize", {
                            "component" : component
                        });
                    }, function(error) {
                        JasperMobile.Callback.Callbacks.failedCallback("JasperMobile.Dashboard.API.events.dashlet.didMaximize.failed", {
                            "error" : JSON.stringify({
                                "code" : error.errorCode,
                                "message" : error.message
                            }),
                            "component" : component
                        });
                    });
                }
            };
        }
    },
    _getDashlets: function(dashboardId) {
        var dashlets;
        var query = ".dashlet";
        if (dashboardId != null) {
            query = "[" + dashboardId + "] > .dashlet";
        }
        dashlets = document.querySelectorAll(query);
        return dashlets;
    },
    _getComponentById: function(id) {
        var components = JasperMobile.Dashboard.API.dashboardObject.data().components;
        for (var i = 0; components.length; ++i) {
            if (components[i].id === id) {
                return components[i];
            }
        }
    },
    _setupFiltersApperance: function() {
        var interval = window.setInterval(function() {
            window.clearInterval(interval);
            var div = document.querySelector(".msPlaceholder > div");
            if (div !== null) {
                var divHeight;
                divHeight = document.querySelector(".msPlaceholder > div").style.height;
                if (divHeight !== 'undefined') {
                    document.querySelector(".msPlaceholder > div").style.height = "";
                }
                document.querySelector(".filterRow > div > div").style.height = "";
            }
        }, 500);
    }
};

// Start Point
document.addEventListener("DOMContentLoaded", function(event) {
    JasperMobile.Callback.onScriptLoaded();
});

window.onerror = function myErrorHandler(message, source, lineno, colno, error) {
    JasperMobile.Callback.Callbacks.failedCallback("JasperMobile.Events.Window.OnError", {
        "error" : JSON.stringify({
            "code" : "window.onerror",
            "message" : message + " " + source + " " + lineno + " " + colno + " " + error,
            "source" : source
        })
    });
    return false;
};