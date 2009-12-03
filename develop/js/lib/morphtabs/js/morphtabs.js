Fx.MorphElement = new Class({
    Extends: Fx.Morph,
    options: {
        wrap: true,
        wrapClass: "morphElementWrap",
        FxTransition: $empty,
        hideOnInitialize: true
    },
    initialize: function (B, A) {
        this.setOptions(A);
        this.parent(B, A);
        if (this.options.wrap) {
            this.setup()
        }
        if (this.options.hideOnInitialize) {
            this.element.store("fxEffect:flag", "hide");
            this.getFx("fade")
        }
    },
    setup: function () {
        var A = new Element("div", {
            id: this.element.get("id") + "_wrap",
            "class": this.options.wrapClass,
            styles: {
                height: this.options.height,
                width: this.options.width,
                overflow: "hidden"
            }
        }).wraps(this.element)
    },
    getFx: function (C) {
        var A = this.element.retrieve("fxEffect:flag", "show");
        var B = {
            "margin-top": [0, 0],
            "margin-left": [0, 0],
            width: [this.options.width, this.options.width],
            height: [this.options.height, this.options.height],
            opacity: [1, 1]
        };
        fxEffect = this.element.get("morph", this.options.FxTransition);
        C = C.split(":");
        if (C.length > 1) {
            C = Fx.MorphElement.Effects[C[0]][C[1]][A]
        } else {
            C = Fx.MorphElement.Effects[C[0]][A]
        }
        $H(C).each(function (E, D) {
            E.each(function (G, F) {
                if ($type(G) == "string") {
                    E[F] = G.substitute({
                        width: this.options.width,
                        height: this.options.height
                    })
                }
            }.bind(this));
            B[D] = E
        }.bind(this));
        B = fxEffect.start(B);
        this.element.store("fxEffect:flag", (A == "hide") ? "show" : "hide");
        return B
    }
});
Element.Properties.morphElement = {
    set: function (A) {
        var B = this.retrieve("morphElement");
        if (B) {
            B.cancel()
        }
        return this.eliminate("morphElement").store("morphElement:options", $extend({
            link: "cancel"
        },
        A))
    },
    get: function (A) {
        if (A || !this.retrieve("morphElement")) {
            if (A || !this.retrieve("morphElement:options")) {
                this.set("morphElement", A)
            }
            this.store("morphElement", new Fx.MorphElement(this, this.retrieve("morphElement:options")))
        }
        return this.retrieve("morphElement")
    }
};
Element.implement({
    morphElement: function (A) {
        this.get("morphElement").getFx(A);
        return this
    }
});
Fx.MorphElement.Effects = $H({
    blind: {
        up: {
            hide: {
                height: ["{height}", 0]
            },
            show: {
                "margin-top": ["{height}", 0],
                height: [0, "{height}"]
            }
        },
        down: {
            hide: {
                "margin-top": ["{height}"],
                height: [0]
            },
            show: {
                height: [0, "{height}"]
            }
        },
        left: {
            hide: {
                width: ["{width}", 0]
            },
            show: {
                "margin-left": ["{width}", 0],
                width: [0, "{width}"]
            }
        },
        right: {
            hide: {
                "margin-left": ["{width}"],
                width: [0]
            },
            show: {
                width: [0, "{width}"]
            }
        }
    },
    slide: {
        up: {
            hide: {
                "margin-top": [0, "-{height}"],
                width: ["{width}"],
                height: ["{height}"]
            },
            show: {
                "margin-top": ["{height}", 0]
            }
        },
        down: {
            hide: {
                "margin-top": [0, "{height}"],
                width: ["{width}"],
                height: ["{height}"]
            },
            show: {
                "margin-top": ["-{height}", 0]
            }
        },
        left: {
            hide: {
                "margin-left": [0, "-{width}"],
                width: ["{width}"],
                height: ["{height}"]
            },
            show: {
                "margin-left": ["{width}", 0]
            }
        },
        right: {
            hide: {
                "margin-left": [0, "{width}"],
                width: ["{width}"],
                height: ["{height}"]
            },
            show: {
                "margin-left": ["-{width}", 0]
            }
        }
    },
    fade: {
        hide: {
            opacity: [1, 0]
        },
        show: {
            opacity: [0, 1]
        }
    }
});
var SlideShow = new Class({
    start: function () {
        this.slideShow = this.next.periodical(this.options.slideShowDelay * 1000, this)
    },
    stop: function () {
        this.clearChain();
        $clear(this.slideShow)
    }
});
var Tabs = new Class({    
    Implements: [Options, Events, SlideShow],
    options: {
        tabs: ".morphtabs_title li",
        panels: ".morphtabs_panel",
        panelClass: "morphtabs_panel",
        selectedClass: "active",
        mouseOverClass: "over",
        activateOnLoad: "first",
        slideShow: false,
        slideShowDelay: 3,
        ajaxOptions: {},
        onShow: $empty
    },
    initialize: function (B, A) {
        this.setOptions(A);
        this.el = document.id(B);
        this.elid = B;
        this.tabs = $$(this.options.tabs);
        this.panels = $$(this.options.panels);
        this.attach(this.tabs);
        if (this.options.activateOnLoad != "none") {
            if (this.options.activateOnLoad == "first") {
                this.activate(this.tabs[0])
            } else {
                this.activate(this.options.activateOnLoad)
            }
        }
        if (this.options.slideShow) {
            this.start()
        }
    },
    attach: function (A) {
        $$(A).each(function (D) {
            var E = D.retrieve("tab:enter", this.elementEnter.bindWithEvent(this, D));
            var C = D.retrieve("tab:leave", this.elementLeave.bindWithEvent(this, D));
            var B = D.retrieve("tab:click", this.elementClick.bindWithEvent(this, D));
            D.addEvents({
                mouseenter: E,
                mouseleave: C,
                click: B
            })
        },
        this);
        return this
    },
    detach: function (A) {        
        $$(A).each(function (C) {                          
            C.removeEvent("mouseenter", C.retrieve("tab:enter") || $empty);
            C.removeEvent("mouseleave", C.retrieve("tab:leave") || $empty);
            C.removeEvent("mouseclick", C.retrieve("tab:click") || $empty);
            C.eliminate("tab:enter").eliminate("tab:leave").eliminate("tab:click");
            var E = C.getProperty("title");
            var B = this.panels.filter("[id=" + E + "]")[0].dispose();
            var D = C.dispose()            
        },
        this);
        return this
    },
    activate: function (A) {
        A = this.getTab(A);
        if ($type(A) == "element") {
            var B = this.showTab(A);
            this.fireEvent("onShow", [B])
        }
    },
    showTab: function (A) {
        var B = A.getProperty("title");
        this.panels.removeClass(this.options.selectedClass);
        this.activePanel = this.panels.filter("[id=" + B + "]")[0];
        this.activePanel.addClass(this.options.selectedClass);
        this.tabs.removeClass(this.options.selectedClass);
        A.addClass(this.options.selectedClass);
        this.activeTitle = A;
        if (A.getElement("a")) {
            this.getContent()
        }
        return B
    },
    getTab: function (A) {
        if ($type(A) == "string") {
            myTab = $$(this.options.tabs).filter("[title=" + A + "]")[0];
            A = myTab
        }
        return A
    },
    getContent: function () {
        this.activePanel.set("load", this.options.ajaxOptions);
        this.activePanel.load(this.activeTitle.getElement("a").get("href"))
    },
    elementEnter: function (B, A) {
        if (A != this.activeTitle) {
            A.addClass(this.options.mouseOverClass)
        }
    },
    elementLeave: function (B, A) {
        if (A != this.activeTitle) {
            A.removeClass(this.options.mouseOverClass)
        }
    },
    elementClick: function (B, A) {
        B.stop();
        if (A != this.activeTitle) {
            A.removeClass(this.options.mouseOverClass);
            this.activate(A)
        }
        if (this.slideShow) {
            this.setOptions(this.slideShow, false);
            this.stop()
        }
    },
    addTab: function (D, B, C) {
        var E = new Element("li", {
            title: D,
            html: B
        });
        this.tabs.include(E);
        $$(this.options.tabs).getParent().adopt(E);
        var A = new Element("div", {
            id: D,
            "class": this.options.panelClass,
            html: C
        });
        this.panels.include(A);
        this.el.adopt(A);
        this.attach(E);
        return E
    },
    removeTab: function (B) {
        if (this.activeTitle.title == B) {
            this.activate(this.tabs[0])
        }
        var A = $$(this.options.tabs).filter("[title=" + B + "]")[0];
        this.detach(A)
    },
    next: function () {
        var A = this.activeTitle.getNext();
        if (!A) {
            A = this.tabs[0]
        }
        this.activate(A)
    },
    previous: function () {
        var A = this.activeTitle.getPrevious();
        if (!A) {
            A = this.tabs[this.tabs.length - 1]
        }
        this.activate(A)
    }
});
var MorphTabs = new Class({
    Extends: Tabs,
    options: {
        panelWrapClass: "morphtabs_panelwrap",
        TransitionFx: {
            transition: "linear",
            duration: "long"
        },
        panelStartFx: "blind:left",
        panelEndFx: "blind:right"
    },
    initialize: function (B, A) {
        this.firstRun = true;
        this.parent(B, A);
        this.wrap = new Element("div", {
            id: B + "_panelwrap",
            "class": this.options.panelWrapClass
        }).inject(document.id(B));
        this.addToWrap(this.tabs)
    },
    attach: function (A) {
        $$(A).each(function (B) {
            this.parent(B);
            B.store("tab:effect", document.id(B.title).get("morphElement", {
                wrap: false,
                width: this.el.getWidth(),
                height: document.id(B.title).getStyle("height"),
                FxTransition: this.options.TransitionFx
            }))
        },
        this);
        return this
    },
    addToWrap: function (A) {
        $$(A).each(function (B) {
            this.wrap.adopt(document.id(B.title))
        },
        this)
    },
    activate: function (A) {
        A = this.getTab(A);
        if ($type(A) == "element") {
            switch (this.firstRun) {
            case true:
                var B = this.showTab(A);
                break;
            default:
                this.effect = this.activeTitle.retrieve("tab:effect");
                this.activePanel.setStyle("overflow", "hidden");
                this.effect.getFx(this.options.panelStartFx).chain(function () {
                    var C = this.showTab(A)
                }.bind(this));
                break
            }
            if (this.firstRun) {
                this.firstRun = false
            }
            this.fireEvent("onShow", [B])
        }
    },
    showTab: function (A) {
        var B = this.parent(A);
        this.activePanel.setStyle("overflow", "hidden");
        this.effect = A.retrieve("tab:effect");
        this.showTabFx();
        return B
    },
    showTabFx: function () {
        this.effect.getFx(this.options.panelEndFx).chain(function () {
            this.activePanel.setStyle("overflow", "auto")
        }.bind(this))
    },
    changeFx: function (B, A) {
        if (B == "all") {
            B = this.tabs
        }
        A = {
            FxTransition: A
        };
        $$(B).each(function (D) {
            var C = document.id(D.title).retrieve("morphElement");
            C.setOptions(A);
            D.eliminate("tab:effect").store("tab:effect", C)
        }.bind(this))
    },
    elementClick: function (B, A) {
        this.parent(B, A);
        if (this.slideShow) {
            this.activePanel.store("fxEffect:flag", "show")
        }
    },
    addTab: function (C, A, B) {
        var D = this.parent(C, A, B);
        this.addToWrap(D)
    }
});