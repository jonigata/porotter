(function ($hx_exports) { "use strict";
var ArrayUtil = function() { };
ArrayUtil.__name__ = true;
ArrayUtil.shuffle = function(a) {
	var i = a.length;
	while(0 < i) {
		var j = Std.random(i);
		var t = a[--i];
		a[i] = a[j];
		a[j] = t;
	}
	return a;
};
ArrayUtil.sample = function(a) {
	return a[Std.random(a.length)];
};
ArrayUtil.find = function(a,f) {
	var _g = 0;
	while(_g < a.length) {
		var e = a[_g];
		++_g;
		if(f(e)) return e;
	}
	return null;
};
ArrayUtil.find_index = function(a,f) {
	var _g1 = 0;
	var _g = a.length;
	while(_g1 < _g) {
		var i = _g1++;
		if(f(a[i])) return i;
	}
	return null;
};
var DateTools = function() { };
DateTools.__name__ = true;
DateTools.delta = function(d,t) {
	var t1 = d.getTime() + t;
	var d1 = new Date();
	d1.setTime(t1);
	return d1;
};
var EReg = function(r,opt) {
	opt = opt.split("u").join("");
	this.r = new RegExp(r,opt);
};
EReg.__name__ = true;
EReg.prototype = {
	match: function(s) {
		if(this.r.global) this.r.lastIndex = 0;
		this.r.m = this.r.exec(s);
		this.r.s = s;
		return this.r.m != null;
	}
	,matched: function(n) {
		if(this.r.m != null && n >= 0 && n < this.r.m.length) return this.r.m[n]; else throw "EReg::matched";
	}
	,matchedRight: function() {
		if(this.r.m == null) throw "No string matched";
		var sz = this.r.m.index + this.r.m[0].length;
		return this.r.s.substr(sz,this.r.s.length - sz);
	}
	,matchedPos: function() {
		if(this.r.m == null) throw "No string matched";
		return { pos : this.r.m.index, len : this.r.m[0].length};
	}
	,__class__: EReg
};
var FormUtil = function() { };
FormUtil.__name__ = true;
FormUtil.clearSelect = function(select) {
	Misc.disable(select);
	select.html("");
};
FormUtil.getSelected = function(select) {
	return new $(select).find(":selected");
};
FormUtil.setSubmitAction = function(dialog,f) {
	var submit = dialog.find(":submit");
	submit.unbind("click");
	submit.click(function(e) {
		f(e.target);
		return false;
	});
};
FormUtil.setupRadio = function(root,name) {
	var radios = root.find("[name=\"" + name + "\"]");
	var onChange = function() {
		radios.each(function(i,elem) {
			var radio = new $(elem);
			var label = radio.closest("label.radio");
			var inputs = label.find("input:not(:radio),select");
			var checked = radio["is"](":checked");
			FormUtil.updateStatus(inputs,["active","loaded"],"active",checked);
		});
		return true;
	};
	onChange();
	radios.unbind("change");
	radios.change(onChange);
};
FormUtil.setupEditGroupButton = function(button) {
	FormUtil.updateStatus(button,["active","loaded"],"loaded",false);
	var groupId = Std.parseInt(button.attr("group-id"));
	var storeName = button.attr("store");
	var displayId = button.attr("display");
	var form = button.closest("form");
	var store = form.find("[name=\"" + storeName + "\"]");
	var display = form.find("#" + displayId);
	$.ajax({ url : "/foo/ajax/v/group", method : "get", data : { group : groupId}, dataType : "jsonp"}).done(function(data) {
		FormUtil.updateStatus(button,["active","loaded"],"loaded",true);
		FormUtil.updateGroupStore(store,data);
		FormUtil.updateGroupDisplay(display,data);
		button.unbind("click");
		button.click(function(e) {
			FormUtil.editGroup(data,function(data1) {
				FormUtil.updateGroupStore(store,data1);
				FormUtil.updateGroupDisplay(display,data1);
			});
			return false;
		});
	});
};
FormUtil.setupUserSelect = function(userSelect,onLoad,onChange) {
	Misc.disable(userSelect);
	FormUtil.clearSelect(userSelect);
	$.ajax({ url : "/foo/ajax/v/userlist", method : "get"}).done(function(data) {
		userSelect.append("<option value=\"0\">所有者を選択</option>");
		var users = $.parseJSON(data);
		var _g = 0;
		while(_g < users.length) {
			var v = users[_g];
			++_g;
			var userId = v[0];
			var username = v[1];
			var userLabel = v[2];
			var userIcon = v[3];
			userSelect.append("<option value=\"" + userId + "\" user-id=\"" + userId + "\" username=\"" + username + "\" label=\"" + userLabel + "\" icon=\"" + userIcon + "\">" + username + " - " + userLabel + "</option>");
		}
		userSelect.unbind("change");
		userSelect.change(function(e) {
			onChange(FormUtil.getSelected(e.target).val());
		});
		Misc.enable(userSelect);
		onLoad();
	});
};
FormUtil.setupBoardSelect = function(boardSelect,userId,filter,onChange) {
	$.ajax({ url : "/foo/ajax/v/boardlist?user=${userId}", method : "get"}).done(function(data) {
		boardSelect.append("<option value=\"0\">ボードを選択</option>");
		var boards = $.parseJSON(data);
		var _g = 0;
		while(_g < boards.length) {
			var v = boards[_g];
			++_g;
			var boardId = v.boardId;
			var boardlabel = v.label;
			var disabled;
			if(filter(boardId)) disabled = ""; else disabled = " disabled=\"disabled\"";
			boardSelect.append("<option value=\"" + boardId + "\"" + disabled + ">" + boardlabel + "</option>");
		}
		boardSelect.unbind("change");
		boardSelect.change(function(e) {
			onChange(FormUtil.getSelected(e.target).val());
		});
		Misc.enable(boardSelect);
	});
};
FormUtil.setupRibbonSelect = function(ribbonSelect,boardId,disableDup,f) {
	$.ajax({ url : "/foo/ajax/v/ribbonlist?board=" + boardId, method : "get"}).done(function(data) {
		ribbonSelect.append("<option value=\"0\">リボンを選択</option>");
		var ribbons = $.parseJSON(data);
		var _g = 0;
		while(_g < ribbons.length) {
			var v = ribbons[_g];
			++_g;
			var ribbonId = v.ribbonId;
			var ribbonLabel = v.label;
			var disabled = "";
			if(disableDup && 0 < new $("[ribbon-id=\"" + ribbonId + "\"]").length) disabled = " disabled=\"disabled\"";
			ribbonSelect.append("<option value=\"" + ribbonId + "\"" + disabled + ">" + ribbonLabel + "</option>");
		}
		ribbonSelect.unbind("change");
		ribbonSelect.change(function(e) {
			f(FormUtil.getSelected(e.target).val());
		});
		Misc.enable(ribbonSelect);
	});
};
FormUtil.setupRemovedRibbonSelect = function(ribbonSelect,boardId,disableDup,f) {
	$.ajax({ url : "/foo/ajax/v/removedribbonlist?board=" + boardId, method : "get"}).done(function(data) {
		ribbonSelect.append("<option value=\"0\">リボンを選択</option>");
		var ribbons = $.parseJSON(data);
		var _g = 0;
		while(_g < ribbons.length) {
			var v = ribbons[_g];
			++_g;
			var ribbonId = v[0];
			var ribbonLabel = v[1];
			ribbonSelect.append("<option value=\"" + ribbonId + "\">" + ribbonLabel + "</option>");
		}
		ribbonSelect.unbind("change");
		ribbonSelect.change(function(e) {
			f(FormUtil.getSelected(e.target).val());
		});
		Misc.enable(ribbonSelect);
	});
};
FormUtil.doBoardEditingAction = function(obj,f) {
	FormUtil.postForm(FormUtil.getForm(obj),function(s) {
		f(s.version);
	});
	return false;
};
FormUtil.doPost = function(obj) {
	FormUtil.postForm(FormUtil.getForm(obj),function(s) {
		Misc.redirect(Misc.makeBoardUrl(s[0],s[1]));
	});
	return false;
};
FormUtil.getForm = function(obj) {
	var e = new $(obj);
	if(e["is"]("form")) return e; else return e.closest("form");
};
FormUtil.postForm = function(form,f) {
	$.ajax({ url : form.attr("action"), method : form.attr("method"), data : form.serialize(), dataType : "jsonp"}).done(function(data) {
		f(data);
	});
};
FormUtil.updateStatus = function(all,statuses,s,f) {
	if(f) all.addClass(s); else all.removeClass(s);
	all.each(function(i,elem) {
		var e = new $(elem);
		var _g = 0;
		while(_g < statuses.length) {
			var s1 = statuses[_g];
			++_g;
			if(!e.hasClass(s1)) {
				Misc.disable(e);
				return;
			}
		}
		Misc.enable(e);
	});
};
FormUtil.updateGroupStore = function(store,data) {
	var memberSet = [];
	var members = data.members;
	var _g = 0;
	while(_g < members.length) {
		var v = members[_g];
		++_g;
		memberSet.push(v.userId);
	}
	memberSet.sort(function(a,b) {
		return a - b;
	});
	store.val(JSON.stringify(memberSet));
};
FormUtil.updateGroupDisplay = function(display,data) {
	var members = data.members;
	display.html("");
	if(members.length == 0) display.html("<p>ユーザが含まれていません</p>"); else {
		var _g = 0;
		while(_g < members.length) {
			var v = members[_g];
			++_g;
			display.append(Misc.gravatar(v.gravatar,16,v.userId,v.username,v.label));
		}
	}
	display.find("img").tooltip();
	display.find("img").draggable({ revert : "invalid"});
	FormUtil.updateMemberSet(display);
};
FormUtil.updateMemberSet = function(display) {
	var memberSet = [];
	display.find("img").each(function(i,elem) {
		var e = new $(elem);
		memberSet.push(Std.parseInt(e.attr("user-id")));
	});
	memberSet.sort(function(a,b) {
		return a - b;
	});
	display.attr("member-set",JSON.stringify(memberSet));
};
FormUtil.editGroup = function(data,cb) {
	var dialog = new $("#edit-group");
	var display = dialog.find(".group-members");
	var submit = dialog.find("input:submit");
	submit.unbind("click");
	submit.click(function() {
		cb(data);
		dialog.close();
		return false;
	});
	FormUtil.updateGroupDisplay(display,data);
	var oldMemberSet = display.attr("member-set");
	var groupName = dialog.find("[name=\"group_name\"]");
	groupName.val(data.name);
	Misc.setEnabled(groupName,data.nameEditable);
	var userSelect = dialog.find("[name=\"user\"]");
	var updateUI = function() {
		userSelect.val(0);
		userSelect.find("option").each(function(i,elem) {
			var e = new $(elem);
			var userId = e.attr("user-id");
			var filter = "[user-id=\"" + userId + "\"]";
			Misc.setEnabled(e,display.find(filter).length == 0);
		});
		Misc.setEnabled(submit,oldMemberSet != display.attr("member-set"));
	};
	var trash = dialog.find(".group-member-trash");
	trash.droppable({ accept : "[user-id]", drop : function(e1,ui) {
		var e2 = new $(ui.draggable);
		e2.tooltip("hide");
		data.members = data.members.filter(function(n) {
			return n.userId != Std.parseInt(e2.attr("user-id"));
		});
		FormUtil.updateGroupDisplay(display,data);
		console.log(display.attr("member-set"));
		updateUI();
	}});
	var addButton = dialog.find("#add-member");
	Misc.disable(addButton);
	FormUtil.setupUserSelect(userSelect,function() {
		updateUI();
	},function(userId1) {
		Misc.setEnabled(addButton,userId1 != 0);
	});
	addButton.unbind("click");
	addButton.click(function() {
		display.find("p").remove("");
		var s = userSelect.find(":selected");
		var member = { userId : Std.parseInt(s.attr("user-id")), username : s.attr("username"), label : s.attr("label"), gravatar : s.attr("icon")};
		data.members.push(member);
		FormUtil.updateGroupDisplay(display,data);
		updateUI();
	});
	updateUI();
	dialog.justModal({ overlayZIndex : 20050, modalZIndex : 20100});
};
var HxOverrides = function() { };
HxOverrides.__name__ = true;
HxOverrides.cca = function(s,index) {
	var x = s.charCodeAt(index);
	if(x != x) return undefined;
	return x;
};
HxOverrides.substr = function(s,pos,len) {
	if(pos != null && pos != 0 && len != null && len < 0) return "";
	if(len == null) len = s.length;
	if(pos < 0) {
		pos = s.length + pos;
		if(pos < 0) pos = 0;
	} else if(len < 0) len = s.length + len - pos;
	return s.substr(pos,len);
};
var Interval = function(b,e) {
	this.b = b;
	this.e = e;
};
Interval.__name__ = true;
Interval.prototype = {
	__class__: Interval
};
var Intervals = function() {
	this.elems = new Array();
};
Intervals.__name__ = true;
Intervals.prototype = {
	lt: function(x,y) {
		return x > y;
	}
	,leq: function(x,y) {
		return x >= y;
	}
	,add: function(b,e) {
		var _g = this;
		if(this.leq(e,b)) throw "arguments must be b <= e";
		if(b == e) return;
		var next = ArrayUtil.find_index(this.elems,function(r) {
			return _g.lt(b,r.b);
		});
		if(next == null) next = this.elems.length;
		var interval = new Interval(b,e);
		if(0 < next && this.leq(b,this.elems[next - 1].e)) {
			if(this.lt(this.elems[next - 1].e,e)) this.elems[next - 1].e = e;
		} else {
			this.elems.splice(next,0,interval);
			next++;
		}
		var base = this.elems[next - 1];
		var remove_last = next;
		while(remove_last < this.elems.length && this.leq(this.elems[remove_last].e,base.e)) remove_last++;
		if(next < remove_last) this.elems.splice(next,remove_last - next);
		if(next < this.elems.length) {
			if(this.leq(this.elems[next].b,base.e)) {
				base.e = this.elems[next].e;
				this.elems.splice(next,1);
			}
		}
	}
	,print: function() {
		var s = "";
		var _g = 0;
		var _g1 = this.elems;
		while(_g < _g1.length) {
			var v = _g1[_g];
			++_g;
			s += "" + v.b + "-" + v.e + " ";
		}
		console.log(s);
	}
	,to_array: function() {
		var a = [];
		var _g = 0;
		var _g1 = this.elems;
		while(_g < _g1.length) {
			var v = _g1[_g];
			++_g;
			a.push([v.b,v.e]);
		}
		return a;
	}
	,from_array: function(a) {
		var _g = 0;
		while(_g < a.length) {
			var v = a[_g];
			++_g;
			this.add(v[0],v[1]);
		}
	}
	,__class__: Intervals
};
var List = function() {
	this.length = 0;
};
List.__name__ = true;
List.prototype = {
	add: function(item) {
		var x = [item];
		if(this.h == null) this.h = x; else this.q[1] = x;
		this.q = x;
		this.length++;
	}
	,push: function(item) {
		var x = [item,this.h];
		this.h = x;
		if(this.q == null) this.q = x;
		this.length++;
	}
	,first: function() {
		if(this.h == null) return null; else return this.h[0];
	}
	,pop: function() {
		if(this.h == null) return null;
		var x = this.h[0];
		this.h = this.h[1];
		if(this.h == null) this.q = null;
		this.length--;
		return x;
	}
	,isEmpty: function() {
		return this.h == null;
	}
	,iterator: function() {
		return { h : this.h, hasNext : function() {
			return this.h != null;
		}, next : function() {
			if(this.h == null) return null;
			var x = this.h[0];
			this.h = this.h[1];
			return x;
		}};
	}
	,__class__: List
};
var IMap = function() { };
IMap.__name__ = true;
Math.__name__ = true;
var Misc = function() { };
Misc.__name__ = true;
Misc.redirect = function(url) {
	window.location.href = url;
};
Misc.enable = function(e) {
	e.removeAttr("disabled");
};
Misc.disable = function(e) {
	e.attr("disabled","disabled");
};
Misc.setEnabled = function(e,f) {
	if(f) Misc.enable(e); else Misc.disable(e);
};
Misc.gravatar = function(hash,size,userId,username,label) {
	if(label == null) label = "";
	if(username == null) username = "";
	if(userId == null) userId = 0;
	return "<img src=\"http://www.gravatar.com/avatar/" + hash + "?s=" + size + "&d=mm\" alt=\"gravatar\" user-id=\"" + userId + "\" username=\"" + username + "\" title=\"" + label + "\" data-toggle=\"tooltip\"/>";
};
Misc.tooltip = function(s,desc) {
	return "<a href=\"#\" data-toggle=\"tooltip\" title=\"" + desc + "\" onmouseover=\"$(this).tooltip('show');\" onmouseout=\"$(this).tooltip('hide');\">" + s + "</a>";
};
Misc.makeBoardUrl = function(username,boardname) {
	var urlinfo = new $("#basic-data");
	var base_url = urlinfo.attr("base-url");
	return "${base_url}/${username}/${boardname}";
};
var MyPage = $hx_exports.MyPage = function() { };
MyPage.__name__ = true;
MyPage.main = function() {
};
MyPage.testIt = function() {
};
MyPage.init = function() {
	new $("[timeline-id]").each(function(i,elem) {
		var timeline = new $(elem);
		MyPage.fillTimeline(timeline,null);
		if(!timeline["is"]("[editable=\"true\"]")) return;
		timeline.sortable({ handle : ".drag-handle", connectWith : "[timeline-id][editable=\"true\"]", update : function(event,ui) {
			if(ui.sender == null) {
				if(ui.item.parent()[0] == timeline[0]) MyPage.moveArticle(ui.item); else {
				}
			} else MyPage.transferArticle(ui.item,ui.sender);
		}});
	});
	var ribbons = new $(".workspace > ul");
	ribbons.sortable({ handle : ".ribbon-header > h1"});
	var workspace = new $(".workspace");
	workspace.lemmonSlider({ controls : ".controls"});
	var dropdown = new $(".dropdown-toggle");
	dropdown.dropdown();
	var $window = new $(window);
	$window.resize(function(e) {
		var ps_container = new $(".ps-container");
		ps_container.perfectScrollbar("update");
	});
};
MyPage.toggleComments = function(obj) {
	var entry = MyPage.getEntry(obj);
	var comments = entry.find("> .comments");
	if(comments["is"](":visible")) MyPage.closeComments(comments); else MyPage.openComments(comments);
	MyPage.updateCommentDisplayText(entry);
	MyPage.subscribeTimelines();
	MyPage.subscribePosts();
	MyPage.saveCommentsOpenStates();
};
MyPage.toggleCommentForm = function(obj) {
	var commentForm = MyPage.getEntry(obj).find("> .comment-form");
	commentForm.toggle();
	if(commentForm["is"](":visible")) {
		MyPage.scrollToElement(commentForm);
		commentForm.find("textarea").focus();
	}
	MyPage.saveCommentFormOpenStates();
};
MyPage.scrollToEntryTail = function(obj) {
	var entry = MyPage.getEntry(obj);
	MyPage.scrollToElement(entry);
	entry.find("> .comment-form").find("textarea").focus();
};
MyPage.postArticle = function(ribbonId,form) {
	$.ajax({ url : "/foo/ajax/m/newarticle", method : "post", data : { content : new $(form).find("[name=\"content\"]").val(), ribbon : ribbonId}}).done(function() {
	});
	form.find("[name=\"content\"]").val("");
	form.find("textarea").focus();
};
MyPage.postComment = function(ribbonId,timelineId,form) {
	$.ajax({ url : "/foo/ajax/m/newcomment", method : "post", data : { parent : new $(form).find("[name=\"parent\"]").val(), content : new $(form).find("[name=\"content\"]").val(), ribbon : ribbonId, timeline : timelineId}}).done(function() {
		MyPage.openComments(MyPage.getEntry(form).find("> .comments"));
		MyPage.saveCommentFormOpenStates();
	});
	form.find("[name=\"content\"]").val("");
	form.find("textarea").focus();
};
MyPage.favor = function(ribbonId,postId) {
	$.ajax({ url : "/foo/ajax/m/favor", method : "post", data : { ribbon : ribbonId, target : postId}});
};
MyPage.unfavor = function(ribbonId,postId) {
	$.ajax({ url : "/foo/ajax/m/unfavor", method : "post", data : { ribbon : ribbonId, target : postId}});
};
MyPage.continueReading = function(obj) {
	var e = new $(obj);
	var timeline = e.closest(".timeline");
	var newestScore = e.attr("newest-score");
	var oldestScore = MyPage.kickUndefined(e.attr("oldest-score"));
	MyPage.fetchTimeline(timeline,newestScore,oldestScore,null);
};
MyPage.chooseStamp = function(obj,ribbonId,timelineId) {
	var chooser = new $("#stamp-chooser");
	chooser.find("a").each(function(i,elem) {
		var e = new $(elem);
		e.unbind("click");
		e.click(function(e1) {
			MyPage.postStamp(ribbonId,timelineId,new $(obj),new $(e1));
			chooser.close();
		});
	});
	chooser.justModal();
};
MyPage.makeBoard = function() {
	var dialog = new $("#make-board");
	dialog.justModal();
};
MyPage.joinBoard = function() {
	var dialog = new $("#join-board");
	var userSelect = dialog.find("[name=\"user\"]");
	var boardSelect = dialog.find("[name=\"board\"]");
	var submit = dialog.find("[type=\"submit\"]");
	var username = MyPage.getUserName();
	var boardMenu = new $("#board-menu");
	var boardExists = function(boardId) {
		var options = boardMenu.find("[board-id=\"" + boardId + "\"]");
		return 0 < options.length;
	};
	boardSelect.val(0);
	MyPage.disable(boardSelect);
	FormUtil.setupUserSelect(userSelect,function() {
		userSelect.find("option").each(function(i,elem) {
			var e = new $(elem);
			MyPage.setEnabled(e,e.attr("username") != MyPage.getUserName());
		});
	},function(userId) {
		MyPage.disable(submit);
		MyPage.clearSelect(boardSelect);
		if(userId == 0) return;
		FormUtil.setupBoardSelect(boardSelect,userId,function(boardId1) {
			return !boardExists(boardId1);
		},function(boardId2) {
			MyPage.setEnabled(submit,boardId2 != 0);
		});
	});
	dialog.justModal();
};
MyPage.makeRibbon = function() {
	var dialog = new $("#make-ribbon");
	FormUtil.setSubmitAction(dialog,function(submit) {
		dialog.close();
		FormUtil.doBoardEditingAction(submit,function(version) {
			MyPage.loadBoard(MyPage.getBoardId(),version);
		});
	});
	dialog.justModal();
};
MyPage.joinRibbon = function(ownername) {
	var dialog = new $("#join-ribbon");
	var userSelect = dialog.find("[name=\"user\"]");
	var boardSelect = dialog.find("[name=\"board\"]");
	var ribbonSelect = dialog.find("[name=\"ribbon\"]");
	var submit = dialog.find("[type=\"submit\"]");
	var currentBoardId = MyPage.getBoardId();
	boardSelect.val(0);
	MyPage.disable(boardSelect);
	ribbonSelect.val(0);
	MyPage.disable(ribbonSelect);
	FormUtil.setupUserSelect(userSelect,function() {
	},function(userId) {
		MyPage.disable(submit);
		MyPage.clearSelect(boardSelect);
		MyPage.clearSelect(ribbonSelect);
		if(userId == 0) return;
		FormUtil.setupBoardSelect(boardSelect,userId,function(boardId) {
			return boardId != currentBoardId;
		},function(boardId1) {
			Misc.disable(submit);
			FormUtil.clearSelect(ribbonSelect);
			if(boardId1 == 0) return;
			FormUtil.setupRibbonSelect(ribbonSelect,boardId1,true,function(ribbonId) {
				MyPage.setEnabled(submit,ribbonId != 0);
			});
		});
	});
	FormUtil.setSubmitAction(dialog,function(submit1) {
		dialog.close();
		FormUtil.doBoardEditingAction(submit1,function(version) {
			MyPage.loadBoard(MyPage.getBoardId(),version);
		});
	});
	dialog.justModal();
};
MyPage.restoreRibbon = function(boardId) {
	var dialog = new $("#restore-ribbon");
	var ribbonSelect = dialog.find("[name=\"ribbon\"]");
	var submit = dialog.find("[type=\"submit\"]");
	FormUtil.clearSelect(ribbonSelect);
	FormUtil.setupRemovedRibbonSelect(ribbonSelect,boardId,true,function(ribbonId) {
		MyPage.setEnabled(submit,ribbonId != 0);
	});
	FormUtil.setSubmitAction(dialog,function(submit1) {
		dialog.close();
		FormUtil.doBoardEditingAction(submit1,function(version) {
			MyPage.loadBoard(MyPage.getBoardId(),version);
		});
	});
	dialog.justModal();
};
MyPage.closeRibbon = function(obj,boardId) {
	var ribbon = new $(obj).closest(".ribbon");
	var ribbonId = ribbon.attr("ribbon-id");
	$.ajax({ url : "/foo/ajax/m/closeribbon", method : "post", data : { board : boardId, ribbon : ribbonId}, dataType : "jsonp"}).done(function(data) {
		MyPage.setBoardVersion(data.version);
		ribbon.closest(".ribbon-outer").remove();
	});
};
MyPage.editBoardSettings = function() {
	var dialog = new $("#board-settings");
	FormUtil.setupRadio(dialog,"read_permission");
	FormUtil.setupRadio(dialog,"write_permission");
	FormUtil.setupRadio(dialog,"edit_permission");
	FormUtil.setupEditGroupButton(dialog.find("#edit-readable-group"));
	FormUtil.setupEditGroupButton(dialog.find("#edit-writable-group"));
	FormUtil.setupEditGroupButton(dialog.find("#edit-editable-group"));
	FormUtil.setSubmitAction(dialog,function(submit) {
		dialog.close();
		FormUtil.doBoardEditingAction(submit,function(version) {
			MyPage.loadBoard(MyPage.getBoardId(),version);
		});
	});
	dialog.justModal();
};
MyPage.editRibbonSettings = function(dialog,boardId,ribbonId) {
	FormUtil.setupRadio(dialog,"read_permission");
	FormUtil.setupRadio(dialog,"write_permission");
	FormUtil.setupRadio(dialog,"edit_permission");
	FormUtil.setupEditGroupButton(dialog.find("#edit-readable-group"));
	FormUtil.setupEditGroupButton(dialog.find("#edit-writable-group"));
	FormUtil.setupEditGroupButton(dialog.find("#edit-editable-group"));
	FormUtil.setSubmitAction(dialog,function(submit) {
		dialog.close();
		FormUtil.doBoardEditingAction(submit,function(version) {
			console.log(MyPage.getBoardVersion());
			console.log(version);
			MyPage.loadBoard(MyPage.getBoardId(),version);
		});
	});
	dialog.justModal();
};
MyPage.moveArticle = function(dragging) {
	var ribbonId = Std.parseInt(dragging.parent().attr("ribbon-id"));
	var postId = Std.parseInt(dragging.attr("post-id"));
	var target = dragging.next();
	var targetId = 0;
	if(0 < target.length && target["is"]("article")) targetId = target.attr("post-id");
	$.ajax({ url : "/foo/ajax/m/movearticle", method : "post", data : { ribbon : ribbonId, source : postId, target : targetId}}).done(function(data) {
	});
};
MyPage.transferArticle = function(dragging,sourceRibbon) {
	var sourceRibbonId = Std.parseInt(sourceRibbon.attr("ribbon-id"));
	var targetRibbon = dragging.parent();
	var targetRibbonId = Std.parseInt(targetRibbon.attr("ribbon-id"));
	var postId = Std.parseInt(dragging.attr("post-id"));
	var target = dragging.next();
	var targetId = 0;
	if(0 < target.length && target["is"]("article")) targetId = target.attr("post-id");
	$.ajax({ url : "/foo/ajax/m/transferarticle", method : "post", data : { source_ribbon : sourceRibbonId, target_ribbon : targetRibbonId, source : postId, target : targetId}}).done(function(data) {
	});
};
MyPage.doRibbonTest = function(ribbonId) {
	$.ajax({ url : "/foo/ajax/m/ribbontest", method : "post", data : { ribbon : ribbonId}}).done(function(data) {
	});
};
MyPage.getUserName = function() {
	return MyPage.getBasicDataAttr("username");
};
MyPage.getUserId = function() {
	return MyPage.getBasicDataAttr("user-id");
};
MyPage.getOwnerName = function() {
	return MyPage.getBasicDataAttr("owner-name");
};
MyPage.getReferedName = function() {
	return MyPage.getBasicDataAttr("refered-name");
};
MyPage.getBoardId = function() {
	return Std.parseInt(MyPage.getBasicDataAttr("board-id"));
};
MyPage.getBoardName = function() {
	return MyPage.getBasicDataAttr("board-name");
};
MyPage.getBoardVersion = function() {
	return Std.parseInt(MyPage.getBasicDataAttr("board-version"));
};
MyPage.setBoardVersion = function(n) {
	new $("#basic-data").attr("board-version",n);
};
MyPage.getBasicDataAttr = function(a) {
	var data = new $("#basic-data");
	return data.attr(a);
};
MyPage.enable = function(e) {
	e.removeAttr("disabled");
};
MyPage.disable = function(e) {
	e.attr("disabled","disabled");
};
MyPage.setEnabled = function(e,f) {
	if(f) MyPage.enable(e); else MyPage.disable(e);
};
MyPage.postStamp = function(ribbonId,timelineId,source,selected) {
	var form = source.closest(".comment-form").find("> form");
	var image = selected.attr("image");
	$.ajax({ url : "/foo/ajax/m/stamp", method : "post", data : { ribbon : ribbonId, timeline : timelineId, parent : form.find("[name=\"parent\"]").val(), content : image}}).done(function() {
		MyPage.openComments(MyPage.getEntry(form).find("> .comments"));
		MyPage.saveCommentFormOpenStates();
	});
};
MyPage.fillTimeline = function(timeline,version) {
	MyPage.fetchTimeline(timeline,null,null,version);
};
MyPage.fillNewerTimeline = function(timeline,version) {
	var newestScore = 0;
	timeline.children().each(function(i,elem) {
		var e = new $(elem);
		var score = Std.parseInt(e.attr("score"));
		if(newestScore < score) newestScore = score;
	});
	MyPage.fetchTimeline(timeline,null,newestScore,version);
};
MyPage.fetchTimeline = function(oldTimeline,newestScore,oldestScore,version) {
	var ribbonId = Std.parseInt(oldTimeline.attr("ribbon-id"));
	var timelineId = Std.parseInt(oldTimeline.attr("timeline-id"));
	if(timelineId == 0) return;
	var level = Std.parseInt(oldTimeline.attr("level"));
	var writable = oldTimeline.attr("writable") == "true";
	if(!MyPage.startLoad(oldTimeline,version)) return;
	$.ajax({ url : "/foo/ajax/v/timeline", data : { ribbon : ribbonId, timeline : timelineId, newest_score : MyPage.kickUndefined(newestScore), oldest_score : MyPage.kickUndefined(oldestScore), count : 3}, dataType : "jsonp"}).done(function(data) {
		data.level = level;
		var posts = data.posts;
		var _g = 0;
		while(_g < posts.length) {
			var post = posts[_g];
			++_g;
			post.detail = MyPage.formatDetail(post.detail,writable);
		}
		data.intervals = "[[" + Std.string(data.newestScore) + ", " + Std.string(data.oldestScore) + "]]";
		MyPage.finishLoad(oldTimeline,function() {
			var output = MyPage.makeTimeline(data);
			var entry = MyPage.getEntry(oldTimeline);
			var newTimeline = new $(output);
			MyPage.mergeTimeline(oldTimeline,newTimeline);
			if(level == 0) MyPage.loadOpenStates(); else MyPage.subscribePosts();
		});
	});
};
MyPage.traceTimeline = function(timeline) {
	timeline.find("> article").each(function(i,elem) {
		console.log(elem);
	});
};
MyPage.mergeTimeline = function(oldTimeline,newTimeline) {
	if(newTimeline.children().length == 0) {
		MyPage.setupNoArticle(oldTimeline);
		return;
	}
	oldTimeline.find("> .continue-reading").remove();
	var remover = newTimeline.find("> article[removed=\"true\"]");
	remover.each(function(i,elem) {
		var e = new $(elem);
		var postId = e.attr("post-id");
		var filter = "[post-id=\"" + postId + "\"]";
		newTimeline.find(filter).addClass("removing");
		oldTimeline.find(filter).addClass("removing");
	});
	newTimeline.find(".removing").remove();
	oldTimeline.find(".removing").remove();
	newTimeline.children().each(function(i1,elem1) {
		var e1 = new $(elem1);
		var postId1 = e1.attr("post-id");
		oldTimeline.find("[post-id=" + postId1 + "]").addClass("removing");
	});
	oldTimeline.find(".removing").remove();
	var oe = oldTimeline.children().eq(0);
	var ne = newTimeline.children().eq(0);
	while(0 < oe.length && 0 < ne.length) {
		var oldScore = Std.parseInt(oe.attr("score"));
		var newScore = null;
		while(0 < ne.length && oldScore <= (newScore = Std.parseInt(ne.attr("score")))) {
			var newPostId = Std.parseInt(ne.attr("post-id"));
			var oldPostId = Std.parseInt(oe.attr("post-id"));
			var next_ne = ne.next();
			ne.insertBefore(oe);
			ne = next_ne;
		}
		oe = oe.next();
	}
	if(0 < ne.length) {
		var nextne = ne.nextAll();
		oldTimeline.append(ne);
		oldTimeline.append(nextne);
	}
	var intervals = new Intervals();
	var oldTimelineIntervalsAttr = oldTimeline.attr("intervals");
	if(MyPage.kickUndefined(oldTimelineIntervalsAttr) != null) intervals.from_array($.parseJSON(oldTimelineIntervalsAttr));
	var tmpIntervalArray = $.parseJSON(newTimeline.attr("intervals"));
	var _g = 0;
	while(_g < tmpIntervalArray.length) {
		var v = tmpIntervalArray[_g];
		++_g;
		intervals.add(v[0],v[1]);
	}
	var _g1 = 0;
	var _g11 = intervals.elems;
	while(_g1 < _g11.length) {
		var v1 = _g11[_g1];
		++_g1;
		if(v1.e != 0) MyPage.insertContinueReading(oldTimeline,v1.e);
	}
	oldTimeline.attr("intervals",JSON.stringify(intervals.to_array()));
	MyPage.setupDragHandles(oldTimeline);
	MyPage.setupNoArticle(oldTimeline);
	var scrollbox = oldTimeline.closest(".timeline-container").parent();
	scrollbox.perfectScrollbar();
	scrollbox.perfectScrollbar("update");
};
MyPage.setupDragHandles = function(timeline) {
	if(!timeline["is"]("[editable=\"true\"]")) return;
	var articles = timeline.find("> .post");
	articles.find("> .avatar").addClass("drag-handle");
	articles.find("> .entry > .detail").addClass("drag-handle");
};
MyPage.setupNoArticle = function(timeline) {
	timeline.find("> .no-article").remove();
	if(timeline.find("> article").length == 0) timeline.append("<div class=\"no-article\">ポストがありません</div>");
};
MyPage.insertContinueReading = function(timeline,score) {
	var link = new $("<a class=\"continue-reading\" href=\"#\" onclick=\"MyPage.continueReading(this);return false;\">続きを読む</a>");
	link.attr("newest-score",score);
	var a = timeline.children().get();
	var _g = 0;
	while(_g < a.length) {
		var v = a[_g];
		++_g;
		var oldScore = Std.parseInt(new $(v).attr("score"));
		if(oldScore < score) {
			link.attr("oldest-score",oldScore);
			link.insertBefore(v);
			return;
		}
	}
	timeline.append(link);
};
MyPage.saveCommentsOpenStates = function() {
	MyPage.saveOpenStatesAux("comments");
};
MyPage.saveCommentFormOpenStates = function() {
	MyPage.saveOpenStatesAux("comment-form");
};
MyPage.saveOpenStatesAux = function(label) {
	var a = new $("." + label + ":visible").map(function(i,elem) {
		return Std.parseInt(MyPage.getTimelineIdFromEntryContent(elem));
	});
	js.Cookie.set(label,JSON.stringify(a.get()),7);
};
MyPage.loadOpenStates = function() {
	MyPage.loadOpenStatesAux("comments",function(e) {
		MyPage.openComments(e);
	});
	MyPage.loadOpenStatesAux("comment-form",function(e1) {
		e1.show();
	});
	MyPage.subscribeTimelines();
	MyPage.subscribePosts();
};
MyPage.loadOpenStatesAux = function(label,f) {
	var cookie = MyPage.kickUndefined(js.Cookie.get(label));
	if(cookie == null) return;
	var rawOpened = $.parseJSON(cookie);
	var opened = new haxe.ds.StringMap();
	var _g = 0;
	while(_g < rawOpened.length) {
		var v = rawOpened[_g];
		++_g;
		opened.set(v == null?"null":"" + v,v);
	}
	new $(".${label}").each(function(i,elem) {
		var e = new $(elem);
		var timelineId = MyPage.getTimelineIdFromEntryContent(e);
		if(opened.exists(timelineId)) f(e);
	});
};
MyPage.getTimelineIdFromEntryContent = function(e) {
	return MyPage.getEntry(e).find("> .comments > .timeline").attr("timeline-id");
};
MyPage.startLoad = function(timeline,version) {
	if(timeline.attr("loading") != null) {
		var oldWaiting = MyPage.kickUndefined(timeline.attr("waiting"));
		if(version != null && oldWaiting == null || Std.parseInt(oldWaiting) < version) timeline.attr("waiting",version);
		return false;
	}
	if(version != null) {
		if(version <= Std.parseInt(timeline.attr("version"))) return false;
	}
	timeline.attr("loading","true");
	return true;
};
MyPage.finishLoad = function(timeline,f) {
	timeline.removeAttr("loading");
	var waitingVersion = timeline.attr("waiting");
	timeline.removeAttr("waiting");
	f();
	if(waitingVersion != null) MyPage.fillNewerTimeline(timeline,Std.parseInt(waitingVersion));
};
MyPage.scrollToElement = function(e) {
	var $window = new $(window);
	var document = new $(window.document);
	var bottomMargin = 32;
	var target = e.offset().top - $window.height() + e.height() + bottomMargin;
	if(document.scrollTop() < target) document.scrollTop(target);
};
MyPage.getEntry = function(obj) {
	var e = new $(obj);
	if(e["is"](".entry")) return e; else return e.closest(".entry");
};
MyPage.updateCommentDisplayText = function(entry) {
	var comments = entry.find("> .comments");
	var showComment = entry.find("> .operation .show-comment-label");
	if(comments["is"](":visible")) showComment.html("隠す"); else {
		var count = entry.find("> .detail").attr("comment-count");
		showComment.html("×" + count);
	}
};
MyPage.describeSelf = function() {
	if(MyPage.connected) MyPage.io.push("describe",{ user : MyPage.getUserId(), board : MyPage.getBoardId()});
};
MyPage.subscribeBoard = function() {
	if(MyPage.connected) MyPage.io.push("watch-board",{ user : MyPage.getUserId(), targets : [MyPage.getBoardId()]});
};
MyPage.subscribeObservers = function() {
	if(MyPage.connected) MyPage.io.push("watch-observers",{ user : MyPage.getUserId(), targets : [MyPage.getBoardId()]});
};
MyPage.subscribeTimelines = function() {
	if(MyPage.connected) {
		var targets = new $("[timeline-id]:visible").map(function(i,e) {
			return Std.parseInt(new $(e).attr("timeline-id"));
		});
		MyPage.io.push("watch-timeline",{ targets : targets.get()});
	}
};
MyPage.subscribePosts = function() {
	if(MyPage.connected) {
		var targets = new $("[post-id]:visible").map(function(i,e) {
			return Std.parseInt(new $(e).attr("post-id"));
		});
		MyPage.io.push("watch-post",{ targets : targets.get()});
	}
};
MyPage.loadBoard = function(boardId,version) {
	if(MyPage.getBoardVersion() < version) $.ajax({ url : "/foo/ajax/v/workspace", data : { user : MyPage.getUserId(), board : boardId}}).done(function(data) {
		new $(".workspace").replaceWith(data);
		MyPage.init();
		MyPage.startSubscribe();
	});
};
MyPage.loadTimeline = function(timelineId,version) {
	new $("[timeline-id=\"" + timelineId + "\"]").each(function(i,elem) {
		MyPage.fillNewerTimeline(new $(elem),version);
	});
};
MyPage.loadDetail = function(postId,version) {
	var posts = new $("[post-id=\"" + postId + "\"]");
	posts.each(function(i,e) {
		var post = new $(e);
		var ribbonId = post.closest(".ribbon").attr("ribbon-id");
		var writable = post.closest(".timeline").attr("writable") == "true";
		var level = Std.parseInt(post.parent().attr("level"));
		$.ajax({ url : "/foo/ajax/v/detail", data : { ribbon : ribbonId, post : postId, level : level}, dataType : "jsonp"}).done(function(data) {
			var output = MyPage.formatDetail(data,writable);
			var entry = post.find("> .entry");
			entry.find("> .detail").replaceWith(output);
			MyPage.updateCommentDisplayText(entry);
		});
	});
};
MyPage.formatDetail = function(detail,writable) {
	var favoredBy = "";
	var srcFavoredBy = detail.favoredBy;
	var _g = 0;
	while(_g < srcFavoredBy.length) {
		var vv = srcFavoredBy[_g];
		++_g;
		var label = vv.label;
		var icon = vv.gravatar;
		favoredBy += Misc.tooltip(Misc.gravatar(icon,16),label);
	}
	detail.favoredBy = favoredBy;
	detail.elapsed = MyPage.elapsedInWords(detail.elapsed);
	detail.writable = writable;
	return MyPage.applyTemplate("Detail",detail);
};
MyPage.applyTemplate = function(codename,data) {
	var templateCode = haxe.Resource.getString(codename);
	var template = new haxe.Template(templateCode);
	return template.execute(data);
};
MyPage.makeTimeline = function(data) {
	var s = "<section\n   class=\"timeline\"\n   level=\"" + Std.string(data.level) + "\"\n   ribbon-id=\"" + Std.string(data.ribbonId) + "\"\n   timeline-id=\"" + Std.string(data.timelineId) + "\"\n   version=\"" + Std.string(data.timelineVersion) + "\"\n   intervals=\"" + Std.string(data.intervals) + "\"\n   editable=\"" + Std.string(data.editable) + "\"\n   >\n";
	var posts = data.posts;
	var _g = 0;
	while(_g < posts.length) {
		var post = posts[_g];
		++_g;
		s += "\n  <article\n     class=\"post\"\n     score=\"" + Std.string(post.score) + "\"\n     post-id=\"" + Std.string(post.postId) + "\"\n     post-type=\"" + Std.string(post.postType) + "\"\n     version=\"" + Std.string(post.postVersion) + "\"\n     removed=\"" + Std.string(post.removed) + "\"\n     >\n    <div class=\"avatar\">\n      <div class=\"icon\">\n        <img src=\"http://www.gravatar.com/avatar/" + Std.string(post.icon) + "?s=40&d=mm\" alt=\"gravator\"/>\n      </div>\n    </div>\n    <div class=\"entry\">\n      " + Std.string(post.detail) + "\n";
		console.log(post);
		if(post.commendId != 0) {
			s += "\n      <div class=\"operation\">\n        <a class=\"show-comment\" href=\"#\" onclick=\"MyPage.toggleComments(this);return false;\">\n          <img src=\"" + Std.string(post.chatIconUrl) + "\">\n          <span class=\"show-comment-label\">×" + Std.string(post.commentsLength) + "</span>\n        </a>\n";
			if(data.editable) s += "\n        <span class=\"ui-delimiter-8\"></span>\n        <a class=\"post-comment\" href=\"#\" onclick=\"MyPage.toggleCommentForm(this);return false;\">コメントする</a>\n";
			s += "\n                </div>\n";
		}
		if(data.editable) s += "\n      <div class=\"comment-form\">\n        <form>\n          <input type=\"hidden\" name=\"parent\" value=\"" + Std.string(post.postId) + "\"/>\n          <textarea name=\"content\"></textarea><br/>\n          <input class=\"btn btn-primary\" type=\"button\" value=\"投稿\" onclick=\"MyPage.postComment(" + Std.string(data.ribbonId) + ", " + Std.string(post.commentsId) + ", $(this).parent());return false;\"/>\n          <a class=\"btn btn-info\" href=\"#\" onclick=\"MyPage.chooseStamp(this, " + Std.string(data.ribbonId) + ", " + Std.string(post.commentsId) + ");return false;\">スタンプ</a>\n        </form>\n      </div>\n";
		s += "\n      <div class=\"comments\" count=\"" + Std.string(post.commentsLength) + "\">\n        <section class=\"timeline\" level=\"" + Std.string(data.level + 1) + "\" ribbon-id=\"" + Std.string(data.ribbonId) + "\" timeline-id=\"" + Std.string(post.commentsId) + "\" version=\"0\">\n        </section>        \n      </div>\n    </div>\n  </article>\n";
	}
	s += "</section>";
	return s;
};
MyPage.updateObserversWatcher = function(boardId,observers) {
	var observersView = new $("#observers");
	observersView.html("");
	var _g = 0;
	while(_g < observers.length) {
		var v = observers[_g];
		++_g;
		var userId = v.userId;
		var label = v.label;
		var icon = Misc.tooltip(Misc.gravatar(v.gravatar,16),label);
		observersView.append("<span class=\"observer\" user-id=\"" + userId + "\">" + icon + "</span>");
	}
};
MyPage.startSubscribe = function() {
	MyPage.subscribeBoard();
	MyPage.subscribeObservers();
	MyPage.subscribeTimelines();
	MyPage.subscribePosts();
	MyPage.describeSelf();
};
MyPage.startWatch = function() {
	MyPage.io = new RocketIO().connect();
	MyPage.io.on("connect",function(session) {
		MyPage.connected = true;
		console.log("connect");
		MyPage.startSubscribe();
	});
	MyPage.io.on("watch-observers",function(data) {
		console.log("watch-oberservers");
		MyPage.updateObserversWatcher(data.board,data.observers);
	});
	MyPage.io.on("watch-board",function(data1) {
		console.log("watch-board");
		MyPage.loadBoard(data1.board,data1.version);
	});
	MyPage.io.on("watch-timeline",function(data2) {
		console.log("watch-timeline");
		MyPage.loadTimeline(data2.timeline,data2.version);
	});
	MyPage.io.on("watch-post",function(data3) {
		console.log("watch-post");
		MyPage.loadDetail(data3.post,data3.version);
	});
};
MyPage.endWatch = function() {
	MyPage.io.close();
};
MyPage.openComments = function(comments) {
	comments.show();
	var n = MyPage.getEntry(comments).find("> .detail").attr("comments-version");
	if(n != null) {
		var idealVersion = Std.parseInt(n);
		var timeline = comments.find("> .timeline");
		MyPage.fillNewerTimeline(timeline,idealVersion);
	}
};
MyPage.closeComments = function(comments) {
	comments.hide();
};
MyPage.getThis = function() {
	return this;
};
MyPage.isUndefined = function(x) {
	return "undefined" === typeof x;
};
MyPage.kickUndefined = function(x) {
	if(MyPage.isUndefined(x)) return null;
	return x;
};
MyPage.clearSelect = function(select) {
	MyPage.disable(select);
	select.html("");
};
MyPage.updateStatus = function(all,statuses,s,f) {
	if(f) all.addClass(s); else all.removeClass(s);
	all.each(function(i,elem) {
		var e = new $(elem);
		var _g = 0;
		while(_g < statuses.length) {
			var s1 = statuses[_g];
			++_g;
			if(!e.hasClass(s1)) {
				MyPage.disable(e);
				return;
			}
		}
		MyPage.enable(e);
	});
};
MyPage.elapsedInWords = function(elapsedInSeconds) {
	if(elapsedInSeconds <= 10) return "今"; else if(elapsedInSeconds < 60) return "" + elapsedInSeconds + "秒前";
	var elapsedInMinutes = Math.round(elapsedInSeconds / 60);
	if(elapsedInMinutes < 60) return "" + elapsedInMinutes + "分前";
	var elapsedInHours = Math.round(elapsedInMinutes / 60);
	if(elapsedInHours < 24) return "" + elapsedInHours + "時間前";
	var elapsedInDays = Math.round(elapsedInHours / 24);
	if(elapsedInDays < 30) return "" + elapsedInDays + "日前";
	var elapsedInMonths = Math.round(elapsedInDays / 30);
	if(elapsedInMonths < 12) return "" + elapsedInMonths + "ヶ月前";
	var elapsedInYears = Math.round(elapsedInMonths / 12);
	return "" + elapsedInYears + "年前";
};
var Reflect = function() { };
Reflect.__name__ = true;
Reflect.field = function(o,field) {
	try {
		return o[field];
	} catch( e ) {
		return null;
	}
};
var Std = function() { };
Std.__name__ = true;
Std.string = function(s) {
	return js.Boot.__string_rec(s,"");
};
Std.parseInt = function(x) {
	var v = parseInt(x,10);
	if(v == 0 && (HxOverrides.cca(x,1) == 120 || HxOverrides.cca(x,1) == 88)) v = parseInt(x);
	if(isNaN(v)) return null;
	return v;
};
Std.parseFloat = function(x) {
	return parseFloat(x);
};
Std.random = function(x) {
	if(x <= 0) return 0; else return Math.floor(Math.random() * x);
};
var StringBuf = function() {
	this.b = "";
};
StringBuf.__name__ = true;
StringBuf.prototype = {
	add: function(x) {
		this.b += Std.string(x);
	}
	,__class__: StringBuf
};
var StringTools = function() { };
StringTools.__name__ = true;
StringTools.isSpace = function(s,pos) {
	var c = HxOverrides.cca(s,pos);
	return c > 8 && c < 14 || c == 32;
};
StringTools.ltrim = function(s) {
	var l = s.length;
	var r = 0;
	while(r < l && StringTools.isSpace(s,r)) r++;
	if(r > 0) return HxOverrides.substr(s,r,l - r); else return s;
};
StringTools.fastCodeAt = function(s,index) {
	return s.charCodeAt(index);
};
var haxe = {};
haxe.Resource = function() { };
haxe.Resource.__name__ = true;
haxe.Resource.getString = function(name) {
	var _g = 0;
	var _g1 = haxe.Resource.content;
	while(_g < _g1.length) {
		var x = _g1[_g];
		++_g;
		if(x.name == name) {
			if(x.str != null) return x.str;
			var b = haxe.crypto.Base64.decode(x.data);
			return b.toString();
		}
	}
	return null;
};
haxe._Template = {};
haxe._Template.TemplateExpr = { __ename__ : true, __constructs__ : ["OpVar","OpExpr","OpIf","OpStr","OpBlock","OpForeach","OpMacro"] };
haxe._Template.TemplateExpr.OpVar = function(v) { var $x = ["OpVar",0,v]; $x.__enum__ = haxe._Template.TemplateExpr; return $x; };
haxe._Template.TemplateExpr.OpExpr = function(expr) { var $x = ["OpExpr",1,expr]; $x.__enum__ = haxe._Template.TemplateExpr; return $x; };
haxe._Template.TemplateExpr.OpIf = function(expr,eif,eelse) { var $x = ["OpIf",2,expr,eif,eelse]; $x.__enum__ = haxe._Template.TemplateExpr; return $x; };
haxe._Template.TemplateExpr.OpStr = function(str) { var $x = ["OpStr",3,str]; $x.__enum__ = haxe._Template.TemplateExpr; return $x; };
haxe._Template.TemplateExpr.OpBlock = function(l) { var $x = ["OpBlock",4,l]; $x.__enum__ = haxe._Template.TemplateExpr; return $x; };
haxe._Template.TemplateExpr.OpForeach = function(expr,loop) { var $x = ["OpForeach",5,expr,loop]; $x.__enum__ = haxe._Template.TemplateExpr; return $x; };
haxe._Template.TemplateExpr.OpMacro = function(name,params) { var $x = ["OpMacro",6,name,params]; $x.__enum__ = haxe._Template.TemplateExpr; return $x; };
haxe.Template = function(str) {
	var tokens = this.parseTokens(str);
	this.expr = this.parseBlock(tokens);
	if(!tokens.isEmpty()) throw "Unexpected '" + Std.string(tokens.first().s) + "'";
};
haxe.Template.__name__ = true;
haxe.Template.prototype = {
	execute: function(context,macros) {
		if(macros == null) this.macros = { }; else this.macros = macros;
		this.context = context;
		this.stack = new List();
		this.buf = new StringBuf();
		this.run(this.expr);
		return this.buf.b;
	}
	,resolve: function(v) {
		if(Object.prototype.hasOwnProperty.call(this.context,v)) return Reflect.field(this.context,v);
		var $it0 = this.stack.iterator();
		while( $it0.hasNext() ) {
			var ctx = $it0.next();
			if(Object.prototype.hasOwnProperty.call(ctx,v)) return Reflect.field(ctx,v);
		}
		if(v == "__current__") return this.context;
		return Reflect.field(haxe.Template.globals,v);
	}
	,parseTokens: function(data) {
		var tokens = new List();
		while(haxe.Template.splitter.match(data)) {
			var p = haxe.Template.splitter.matchedPos();
			if(p.pos > 0) tokens.add({ p : HxOverrides.substr(data,0,p.pos), s : true, l : null});
			if(HxOverrides.cca(data,p.pos) == 58) {
				tokens.add({ p : HxOverrides.substr(data,p.pos + 2,p.len - 4), s : false, l : null});
				data = haxe.Template.splitter.matchedRight();
				continue;
			}
			var parp = p.pos + p.len;
			var npar = 1;
			var params = [];
			var part = "";
			while(true) {
				var c = HxOverrides.cca(data,parp);
				parp++;
				if(c == 40) npar++; else if(c == 41) {
					npar--;
					if(npar <= 0) break;
				} else if(c == null) throw "Unclosed macro parenthesis";
				if(c == 44 && npar == 1) {
					params.push(part);
					part = "";
				} else part += String.fromCharCode(c);
			}
			params.push(part);
			tokens.add({ p : haxe.Template.splitter.matched(2), s : false, l : params});
			data = HxOverrides.substr(data,parp,data.length - parp);
		}
		if(data.length > 0) tokens.add({ p : data, s : true, l : null});
		return tokens;
	}
	,parseBlock: function(tokens) {
		var l = new List();
		while(true) {
			var t = tokens.first();
			if(t == null) break;
			if(!t.s && (t.p == "end" || t.p == "else" || HxOverrides.substr(t.p,0,7) == "elseif ")) break;
			l.add(this.parse(tokens));
		}
		if(l.length == 1) return l.first();
		return haxe._Template.TemplateExpr.OpBlock(l);
	}
	,parse: function(tokens) {
		var t = tokens.pop();
		var p = t.p;
		if(t.s) return haxe._Template.TemplateExpr.OpStr(p);
		if(t.l != null) {
			var pe = new List();
			var _g = 0;
			var _g1 = t.l;
			while(_g < _g1.length) {
				var p1 = _g1[_g];
				++_g;
				pe.add(this.parseBlock(this.parseTokens(p1)));
			}
			return haxe._Template.TemplateExpr.OpMacro(p,pe);
		}
		if(HxOverrides.substr(p,0,3) == "if ") {
			p = HxOverrides.substr(p,3,p.length - 3);
			var e = this.parseExpr(p);
			var eif = this.parseBlock(tokens);
			var t1 = tokens.first();
			var eelse;
			if(t1 == null) throw "Unclosed 'if'";
			if(t1.p == "end") {
				tokens.pop();
				eelse = null;
			} else if(t1.p == "else") {
				tokens.pop();
				eelse = this.parseBlock(tokens);
				t1 = tokens.pop();
				if(t1 == null || t1.p != "end") throw "Unclosed 'else'";
			} else {
				t1.p = HxOverrides.substr(t1.p,4,t1.p.length - 4);
				eelse = this.parse(tokens);
			}
			return haxe._Template.TemplateExpr.OpIf(e,eif,eelse);
		}
		if(HxOverrides.substr(p,0,8) == "foreach ") {
			p = HxOverrides.substr(p,8,p.length - 8);
			var e1 = this.parseExpr(p);
			var efor = this.parseBlock(tokens);
			var t2 = tokens.pop();
			if(t2 == null || t2.p != "end") throw "Unclosed 'foreach'";
			return haxe._Template.TemplateExpr.OpForeach(e1,efor);
		}
		if(haxe.Template.expr_splitter.match(p)) return haxe._Template.TemplateExpr.OpExpr(this.parseExpr(p));
		return haxe._Template.TemplateExpr.OpVar(p);
	}
	,parseExpr: function(data) {
		var l = new List();
		var expr = data;
		while(haxe.Template.expr_splitter.match(data)) {
			var p = haxe.Template.expr_splitter.matchedPos();
			var k = p.pos + p.len;
			if(p.pos != 0) l.add({ p : HxOverrides.substr(data,0,p.pos), s : true});
			var p1 = haxe.Template.expr_splitter.matched(0);
			l.add({ p : p1, s : p1.indexOf("\"") >= 0});
			data = haxe.Template.expr_splitter.matchedRight();
		}
		if(data.length != 0) l.add({ p : data, s : true});
		var e;
		try {
			e = this.makeExpr(l);
			if(!l.isEmpty()) throw l.first().p;
		} catch( s ) {
			if( js.Boot.__instanceof(s,String) ) {
				throw "Unexpected '" + s + "' in " + expr;
			} else throw(s);
		}
		return function() {
			try {
				return e();
			} catch( exc ) {
				throw "Error : " + Std.string(exc) + " in " + expr;
			}
		};
	}
	,makeConst: function(v) {
		haxe.Template.expr_trim.match(v);
		v = haxe.Template.expr_trim.matched(1);
		if(HxOverrides.cca(v,0) == 34) {
			var str = HxOverrides.substr(v,1,v.length - 2);
			return function() {
				return str;
			};
		}
		if(haxe.Template.expr_int.match(v)) {
			var i = Std.parseInt(v);
			return function() {
				return i;
			};
		}
		if(haxe.Template.expr_float.match(v)) {
			var f = Std.parseFloat(v);
			return function() {
				return f;
			};
		}
		var me = this;
		return function() {
			return me.resolve(v);
		};
	}
	,makePath: function(e,l) {
		var p = l.first();
		if(p == null || p.p != ".") return e;
		l.pop();
		var field = l.pop();
		if(field == null || !field.s) throw field.p;
		var f = field.p;
		haxe.Template.expr_trim.match(f);
		f = haxe.Template.expr_trim.matched(1);
		return this.makePath(function() {
			return Reflect.field(e(),f);
		},l);
	}
	,makeExpr: function(l) {
		return this.makePath(this.makeExpr2(l),l);
	}
	,makeExpr2: function(l) {
		var p = l.pop();
		if(p == null) throw "<eof>";
		if(p.s) return this.makeConst(p.p);
		var _g = p.p;
		switch(_g) {
		case "(":
			var e1 = this.makeExpr(l);
			var p1 = l.pop();
			if(p1 == null || p1.s) throw p1.p;
			if(p1.p == ")") return e1;
			var e2 = this.makeExpr(l);
			var p2 = l.pop();
			if(p2 == null || p2.p != ")") throw p2.p;
			var _g1 = p1.p;
			switch(_g1) {
			case "+":
				return function() {
					return e1() + e2();
				};
			case "-":
				return function() {
					return e1() - e2();
				};
			case "*":
				return function() {
					return e1() * e2();
				};
			case "/":
				return function() {
					return e1() / e2();
				};
			case ">":
				return function() {
					return e1() > e2();
				};
			case "<":
				return function() {
					return e1() < e2();
				};
			case ">=":
				return function() {
					return e1() >= e2();
				};
			case "<=":
				return function() {
					return e1() <= e2();
				};
			case "==":
				return function() {
					return e1() == e2();
				};
			case "!=":
				return function() {
					return e1() != e2();
				};
			case "&&":
				return function() {
					return e1() && e2();
				};
			case "||":
				return function() {
					return e1() || e2();
				};
			default:
				throw "Unknown operation " + p1.p;
			}
			break;
		case "!":
			var e = this.makeExpr(l);
			return function() {
				var v = e();
				return v == null || v == false;
			};
		case "-":
			var e3 = this.makeExpr(l);
			return function() {
				return -e3();
			};
		}
		throw p.p;
	}
	,run: function(e) {
		switch(e[1]) {
		case 0:
			var v = e[2];
			this.buf.add(Std.string(this.resolve(v)));
			break;
		case 1:
			var e1 = e[2];
			this.buf.add(Std.string(e1()));
			break;
		case 2:
			var eelse = e[4];
			var eif = e[3];
			var e2 = e[2];
			var v1 = e2();
			if(v1 == null || v1 == false) {
				if(eelse != null) this.run(eelse);
			} else this.run(eif);
			break;
		case 3:
			var str = e[2];
			if(str == null) this.buf.b += "null"; else this.buf.b += "" + str;
			break;
		case 4:
			var l = e[2];
			var $it0 = l.iterator();
			while( $it0.hasNext() ) {
				var e3 = $it0.next();
				this.run(e3);
			}
			break;
		case 5:
			var loop = e[3];
			var e4 = e[2];
			var v2 = e4();
			try {
				var x = v2.iterator();
				if(x.hasNext == null) throw null;
				v2 = x;
			} catch( e5 ) {
				try {
					if(v2.hasNext == null) throw null;
				} catch( e6 ) {
					throw "Cannot iter on " + Std.string(v2);
				}
			}
			this.stack.push(this.context);
			var v3 = v2;
			while( v3.hasNext() ) {
				var ctx = v3.next();
				this.context = ctx;
				this.run(loop);
			}
			this.context = this.stack.pop();
			break;
		case 6:
			var params = e[3];
			var m = e[2];
			var v4 = Reflect.field(this.macros,m);
			var pl = new Array();
			var old = this.buf;
			pl.push($bind(this,this.resolve));
			var $it1 = params.iterator();
			while( $it1.hasNext() ) {
				var p = $it1.next();
				switch(p[1]) {
				case 0:
					var v5 = p[2];
					pl.push(this.resolve(v5));
					break;
				default:
					this.buf = new StringBuf();
					this.run(p);
					pl.push(this.buf.b);
				}
			}
			this.buf = old;
			try {
				this.buf.add(Std.string(v4.apply(this.macros,pl)));
			} catch( e7 ) {
				var plstr;
				try {
					plstr = pl.join(",");
				} catch( e8 ) {
					plstr = "???";
				}
				var msg = "Macro call " + m + "(" + plstr + ") failed (" + Std.string(e7) + ")";
				throw msg;
			}
			break;
		}
	}
	,__class__: haxe.Template
};
haxe.io = {};
haxe.io.Bytes = function(length,b) {
	this.length = length;
	this.b = b;
};
haxe.io.Bytes.__name__ = true;
haxe.io.Bytes.alloc = function(length) {
	var a = new Array();
	var _g = 0;
	while(_g < length) {
		var i = _g++;
		a.push(0);
	}
	return new haxe.io.Bytes(length,a);
};
haxe.io.Bytes.ofString = function(s) {
	var a = new Array();
	var i = 0;
	while(i < s.length) {
		var c = StringTools.fastCodeAt(s,i++);
		if(55296 <= c && c <= 56319) c = c - 55232 << 10 | StringTools.fastCodeAt(s,i++) & 1023;
		if(c <= 127) a.push(c); else if(c <= 2047) {
			a.push(192 | c >> 6);
			a.push(128 | c & 63);
		} else if(c <= 65535) {
			a.push(224 | c >> 12);
			a.push(128 | c >> 6 & 63);
			a.push(128 | c & 63);
		} else {
			a.push(240 | c >> 18);
			a.push(128 | c >> 12 & 63);
			a.push(128 | c >> 6 & 63);
			a.push(128 | c & 63);
		}
	}
	return new haxe.io.Bytes(a.length,a);
};
haxe.io.Bytes.prototype = {
	get: function(pos) {
		return this.b[pos];
	}
	,set: function(pos,v) {
		this.b[pos] = v & 255;
	}
	,getString: function(pos,len) {
		if(pos < 0 || len < 0 || pos + len > this.length) throw haxe.io.Error.OutsideBounds;
		var s = "";
		var b = this.b;
		var fcc = String.fromCharCode;
		var i = pos;
		var max = pos + len;
		while(i < max) {
			var c = b[i++];
			if(c < 128) {
				if(c == 0) break;
				s += fcc(c);
			} else if(c < 224) s += fcc((c & 63) << 6 | b[i++] & 127); else if(c < 240) {
				var c2 = b[i++];
				s += fcc((c & 31) << 12 | (c2 & 127) << 6 | b[i++] & 127);
			} else {
				var c21 = b[i++];
				var c3 = b[i++];
				var u = (c & 15) << 18 | (c21 & 127) << 12 | (c3 & 127) << 6 | b[i++] & 127;
				s += fcc((u >> 10) + 55232);
				s += fcc(u & 1023 | 56320);
			}
		}
		return s;
	}
	,toString: function() {
		return this.getString(0,this.length);
	}
	,__class__: haxe.io.Bytes
};
haxe.crypto = {};
haxe.crypto.Base64 = function() { };
haxe.crypto.Base64.__name__ = true;
haxe.crypto.Base64.decode = function(str,complement) {
	if(complement == null) complement = true;
	if(complement) while(HxOverrides.cca(str,str.length - 1) == 61) str = HxOverrides.substr(str,0,-1);
	return new haxe.crypto.BaseCode(haxe.crypto.Base64.BYTES).decodeBytes(haxe.io.Bytes.ofString(str));
};
haxe.crypto.BaseCode = function(base) {
	var len = base.length;
	var nbits = 1;
	while(len > 1 << nbits) nbits++;
	if(nbits > 8 || len != 1 << nbits) throw "BaseCode : base length must be a power of two.";
	this.base = base;
	this.nbits = nbits;
};
haxe.crypto.BaseCode.__name__ = true;
haxe.crypto.BaseCode.prototype = {
	initTable: function() {
		var tbl = new Array();
		var _g = 0;
		while(_g < 256) {
			var i = _g++;
			tbl[i] = -1;
		}
		var _g1 = 0;
		var _g2 = this.base.length;
		while(_g1 < _g2) {
			var i1 = _g1++;
			tbl[this.base.b[i1]] = i1;
		}
		this.tbl = tbl;
	}
	,decodeBytes: function(b) {
		var nbits = this.nbits;
		var base = this.base;
		if(this.tbl == null) this.initTable();
		var tbl = this.tbl;
		var size = b.length * nbits >> 3;
		var out = haxe.io.Bytes.alloc(size);
		var buf = 0;
		var curbits = 0;
		var pin = 0;
		var pout = 0;
		while(pout < size) {
			while(curbits < 8) {
				curbits += nbits;
				buf <<= nbits;
				var i = tbl[b.get(pin++)];
				if(i == -1) throw "BaseCode : invalid encoded char";
				buf |= i;
			}
			curbits -= 8;
			out.set(pout++,buf >> curbits & 255);
		}
		return out;
	}
	,__class__: haxe.crypto.BaseCode
};
haxe.ds = {};
haxe.ds.StringMap = function() {
	this.h = { };
};
haxe.ds.StringMap.__name__ = true;
haxe.ds.StringMap.__interfaces__ = [IMap];
haxe.ds.StringMap.prototype = {
	set: function(key,value) {
		this.h["$" + key] = value;
	}
	,get: function(key) {
		return this.h["$" + key];
	}
	,exists: function(key) {
		return this.h.hasOwnProperty("$" + key);
	}
	,__class__: haxe.ds.StringMap
};
haxe.io.Eof = function() { };
haxe.io.Eof.__name__ = true;
haxe.io.Eof.prototype = {
	toString: function() {
		return "Eof";
	}
	,__class__: haxe.io.Eof
};
haxe.io.Error = { __ename__ : true, __constructs__ : ["Blocked","Overflow","OutsideBounds","Custom"] };
haxe.io.Error.Blocked = ["Blocked",0];
haxe.io.Error.Blocked.__enum__ = haxe.io.Error;
haxe.io.Error.Overflow = ["Overflow",1];
haxe.io.Error.Overflow.__enum__ = haxe.io.Error;
haxe.io.Error.OutsideBounds = ["OutsideBounds",2];
haxe.io.Error.OutsideBounds.__enum__ = haxe.io.Error;
haxe.io.Error.Custom = function(e) { var $x = ["Custom",3,e]; $x.__enum__ = haxe.io.Error; return $x; };
var js = {};
js.Boot = function() { };
js.Boot.__name__ = true;
js.Boot.getClass = function(o) {
	if((o instanceof Array) && o.__enum__ == null) return Array; else return o.__class__;
};
js.Boot.__string_rec = function(o,s) {
	if(o == null) return "null";
	if(s.length >= 5) return "<...>";
	var t = typeof(o);
	if(t == "function" && (o.__name__ || o.__ename__)) t = "object";
	switch(t) {
	case "object":
		if(o instanceof Array) {
			if(o.__enum__) {
				if(o.length == 2) return o[0];
				var str = o[0] + "(";
				s += "\t";
				var _g1 = 2;
				var _g = o.length;
				while(_g1 < _g) {
					var i = _g1++;
					if(i != 2) str += "," + js.Boot.__string_rec(o[i],s); else str += js.Boot.__string_rec(o[i],s);
				}
				return str + ")";
			}
			var l = o.length;
			var i1;
			var str1 = "[";
			s += "\t";
			var _g2 = 0;
			while(_g2 < l) {
				var i2 = _g2++;
				str1 += (i2 > 0?",":"") + js.Boot.__string_rec(o[i2],s);
			}
			str1 += "]";
			return str1;
		}
		var tostr;
		try {
			tostr = o.toString;
		} catch( e ) {
			return "???";
		}
		if(tostr != null && tostr != Object.toString) {
			var s2 = o.toString();
			if(s2 != "[object Object]") return s2;
		}
		var k = null;
		var str2 = "{\n";
		s += "\t";
		var hasp = o.hasOwnProperty != null;
		for( var k in o ) {
		if(hasp && !o.hasOwnProperty(k)) {
			continue;
		}
		if(k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" || k == "__properties__") {
			continue;
		}
		if(str2.length != 2) str2 += ", \n";
		str2 += s + k + " : " + js.Boot.__string_rec(o[k],s);
		}
		s = s.substring(1);
		str2 += "\n" + s + "}";
		return str2;
	case "function":
		return "<function>";
	case "string":
		return o;
	default:
		return String(o);
	}
};
js.Boot.__interfLoop = function(cc,cl) {
	if(cc == null) return false;
	if(cc == cl) return true;
	var intf = cc.__interfaces__;
	if(intf != null) {
		var _g1 = 0;
		var _g = intf.length;
		while(_g1 < _g) {
			var i = _g1++;
			var i1 = intf[i];
			if(i1 == cl || js.Boot.__interfLoop(i1,cl)) return true;
		}
	}
	return js.Boot.__interfLoop(cc.__super__,cl);
};
js.Boot.__instanceof = function(o,cl) {
	if(cl == null) return false;
	switch(cl) {
	case Int:
		return (o|0) === o;
	case Float:
		return typeof(o) == "number";
	case Bool:
		return typeof(o) == "boolean";
	case String:
		return typeof(o) == "string";
	case Array:
		return (o instanceof Array) && o.__enum__ == null;
	case Dynamic:
		return true;
	default:
		if(o != null) {
			if(typeof(cl) == "function") {
				if(o instanceof cl) return true;
				if(js.Boot.__interfLoop(js.Boot.getClass(o),cl)) return true;
			}
		} else return false;
		if(cl == Class && o.__name__ != null) return true;
		if(cl == Enum && o.__ename__ != null) return true;
		return o.__enum__ == cl;
	}
};
js.Cookie = function() { };
js.Cookie.__name__ = true;
js.Cookie.set = function(name,value,expireDelay,path,domain) {
	var s = name + "=" + encodeURIComponent(value);
	if(expireDelay != null) {
		var d = DateTools.delta(new Date(),expireDelay * 1000);
		s += ";expires=" + d.toGMTString();
	}
	if(path != null) s += ";path=" + path;
	if(domain != null) s += ";domain=" + domain;
	window.document.cookie = s;
};
js.Cookie.all = function() {
	var h = new haxe.ds.StringMap();
	var a = window.document.cookie.split(";");
	var _g = 0;
	while(_g < a.length) {
		var e = a[_g];
		++_g;
		e = StringTools.ltrim(e);
		var t = e.split("=");
		if(t.length < 2) continue;
		h.set(t[0],decodeURIComponent(t[1].split("+").join(" ")));
	}
	return h;
};
js.Cookie.get = function(name) {
	return js.Cookie.all().get(name);
};
var $_, $fid = 0;
function $bind(o,m) { if( m == null ) return null; if( m.__id__ == null ) m.__id__ = $fid++; var f; if( o.hx__closures__ == null ) o.hx__closures__ = {}; else f = o.hx__closures__[m.__id__]; if( f == null ) { f = function(){ return f.method.apply(f.scope, arguments); }; f.scope = o; f.method = m; o.hx__closures__[m.__id__] = f; } return f; }
Math.NaN = Number.NaN;
Math.NEGATIVE_INFINITY = Number.NEGATIVE_INFINITY;
Math.POSITIVE_INFINITY = Number.POSITIVE_INFINITY;
Math.isFinite = function(i) {
	return isFinite(i);
};
Math.isNaN = function(i1) {
	return isNaN(i1);
};
String.prototype.__class__ = String;
String.__name__ = true;
Array.__name__ = true;
Date.prototype.__class__ = Date;
Date.__name__ = ["Date"];
var Int = { __name__ : ["Int"]};
var Dynamic = { __name__ : ["Dynamic"]};
var Float = Number;
Float.__name__ = ["Float"];
var Bool = Boolean;
Bool.__ename__ = ["Bool"];
var Class = { __name__ : ["Class"]};
var Enum = { };
haxe.Resource.content = [{ name : "Timeline", data : "PHNlY3Rpb24KICAgY2xhc3M9InRpbWVsaW5lIgogICBsZXZlbD0iOjpsZXZlbDo6IgogICByaWJib24taWQ9Ijo6cmliYm9uSWQ6OiIKICAgdGltZWxpbmUtaWQ9Ijo6dGltZWxpbmVJZDo6IgogICB2ZXJzaW9uPSI6OnRpbWVsaW5lVmVyc2lvbjo6IgogICBpbnRlcnZhbHM9Ijo6aW50ZXJ2YWxzOjoiCiAgIGVkaXRhYmxlPSI6OmVkaXRhYmxlOjoiCiAgID4KICA6OmZvcmVhY2ggcG9zdHM6OgogIDxhcnRpY2xlCiAgICAgY2xhc3M9InBvc3QiCiAgICAgc2NvcmU9Ijo6X19jdXJyZW50X18uc2NvcmU6OiIKICAgICBwb3N0LWlkPSI6Ol9fY3VycmVudF9fLnBvc3RJZDo6IgogICAgIHBvc3QtdHlwZT0iOjpfX2N1cnJlbnRfXy5wb3N0VHlwZTo6IgogICAgIHZlcnNpb249Ijo6X19jdXJyZW50X18ucG9zdFZlcnNpb246OiIKICAgICByZW1vdmVkPSI6Ol9fY3VycmVudF9fLnJlbW92ZWQ6OiIKICAgICA+CiAgICA8ZGl2IGNsYXNzPSJhdmF0YXIiPgogICAgICA8ZGl2IGNsYXNzPSJpY29uIj4KICAgICAgICA8aW1nIHNyYz0iaHR0cDovL3d3dy5ncmF2YXRhci5jb20vYXZhdGFyLzo6X19jdXJyZW50X18uaWNvbjo6P3M9NDAmZD1tbSIgYWx0PSJncmF2YXRvciIvPgogICAgICA8L2Rpdj4KICAgIDwvZGl2PgogICAgPGRpdiBjbGFzcz0iZW50cnkiPgogICAgICA6Ol9fY3VycmVudF9fLmRldGFpbDo6CgogICAgICA6OmlmIChfX2N1cnJlbnRfXy5jb21tZW50c0lkICE9IDApOjoKICAgICAgPGRpdiBjbGFzcz0ib3BlcmF0aW9uIj4KICAgICAgICA8YSBjbGFzcz0ic2hvdy1jb21tZW50IiBocmVmPSIjIiBvbmNsaWNrPSJNeVBhZ2UudG9nZ2xlQ29tbWVudHModGhpcyk7cmV0dXJuIGZhbHNlOyI+CiAgICAgICAgICA8aW1nIHNyYz0iOjpjaGF0SWNvblVybDo6Ij4KICAgICAgICAgIDxzcGFuIGNsYXNzPSJzaG93LWNvbW1lbnQtbGFiZWwiPsOXOjpfX2N1cnJlbnRfXy5jb21tZW50c0xlbmd0aDo6PC9zcGFuPgogICAgICAgIDwvYT4KICAgICAgICA6OmlmIGVkaXRhYmxlOjoKICAgICAgICA8c3BhbiBjbGFzcz0idWktZGVsaW1pdGVyLTgiPjwvc3Bhbj4KICAgICAgICA8YSBjbGFzcz0icG9zdC1jb21tZW50IiBocmVmPSIjIiBvbmNsaWNrPSJNeVBhZ2UudG9nZ2xlQ29tbWVudEZvcm0odGhpcyk7cmV0dXJuIGZhbHNlOyI+44Kz44Oh44Oz44OI44GZ44KLPC9hPgogICAgICAgIDo6ZW5kOjoKICAgICAgPC9kaXY+CiAgICAgIDo6ZW5kOjoKCiAgICAgIDo6aWYgZWRpdGFibGU6OgogICAgICA8ZGl2IGNsYXNzPSJjb21tZW50LWZvcm0iPgogICAgICAgIDxmb3JtPgogICAgICAgICAgPGlucHV0IHR5cGU9ImhpZGRlbiIgbmFtZT0icGFyZW50IiB2YWx1ZT0iOjpfX2N1cnJlbnRfXy5wb3N0SWQ6OiIvPgogICAgICAgICAgPHRleHRhcmVhIG5hbWU9ImNvbnRlbnQiPjwvdGV4dGFyZWE+PGJyLz4KICAgICAgICAgIDxpbnB1dCBjbGFzcz0iYnRuIGJ0bi1wcmltYXJ5IiB0eXBlPSJidXR0b24iIHZhbHVlPSLmipXnqL8iIG9uY2xpY2s9Ik15UGFnZS5wb3N0Q29tbWVudCg6OnJpYmJvbklkOjosIDo6X19jdXJyZW50X18uY29tbWVudHNJZDo6LCAkKHRoaXMpLnBhcmVudCgpKTtyZXR1cm4gZmFsc2U7Ii8+CiAgICAgICAgICA8YSBjbGFzcz0iYnRuIGJ0bi1pbmZvIiBocmVmPSIjIiBvbmNsaWNrPSJNeVBhZ2UuY2hvb3NlU3RhbXAodGhpcywgOjpyaWJib25JZDo6LCA6Ol9fY3VycmVudF9fLmNvbW1lbnRzSWQ6Oik7cmV0dXJuIGZhbHNlOyI+44K544K/44Oz44OXPC9hPgogICAgICAgIDwvZm9ybT4KICAgICAgPC9kaXY+CiAgICAgIDo6ZW5kOjoKICAgICAgCiAgICAgIDxkaXYgY2xhc3M9ImNvbW1lbnRzIiBjb3VudD0iOjpfX2N1cnJlbnRfXy5jb21tZW50c0xlbmd0aDo6Ij4KICAgICAgICA8c2VjdGlvbiBjbGFzcz0idGltZWxpbmUiIGxldmVsPSI6OihsZXZlbCArIDEpOjoiIHJpYmJvbi1pZD0iOjpyaWJib25JZDo6IiB0aW1lbGluZS1pZD0iOjpfX2N1cnJlbnRfXy5jb21tZW50c0lkOjoiIHZlcnNpb249IjAiPgogICAgICAgIDwvc2VjdGlvbj4gICAgICAgIAogICAgICA8L2Rpdj4KICAgIDwvZGl2PgogIDwvYXJ0aWNsZT4KICA6OmVuZDo6Cjwvc2VjdGlvbj4K"},{ name : "Detail", data : "PGRpdiBjbGFzcz0iZGV0YWlsIiBjb21tZW50LWNvdW50PSI6OmNvbW1lbnRzTGVuZ3RoOjoiIGNvbW1lbnRzLXZlcnNpb249Ijo6Y29tbWVudHNWZXJzaW9uOjoiPgogIDxkaXYgY2xhc3M9ImF1dGhvciI+CiAgICA8c3Ryb25nPgogICAgICA6OmF1dGhvckxhYmVsOjoKICAgIDwvc3Ryb25nPgogICAgPHNwYW4gY2xhc3M9InVzZXJuYW1lIj4KICAgICAgQDo6YXV0aG9yVXNlcm5hbWU6OgogICAgPC9zcGFuPgogICAgPHNwYW4gY2xhc3M9ImZhdm9yZWQtYnkiPgogICAgICA6OmZhdm9yZWRCeTo6CiAgICA8L3NwYW4+CiAgICA8c3BhbiBjbGFzcz0iZWxhcHNlZCI+CiAgICAgIDo6ZWxhcHNlZDo6CiAgICA8L3NwYW4+CiAgICA8c3BhbiBjbGFzcz0iZmF2b3JpdGUiPgogICAgICA6OmlmICh1c2VyRXhpc3RzKTo6CiAgICAgIDo6aWYgKHdyaXRhYmxlKTo6CiAgICAgIDo6aWYgKGZhdm9yZWQpOjoKICAgICAgPGEgaHJlZj0iIyIgb25jbGljaz0iTXlQYWdlLnVuZmF2b3IoOjpyaWJib25JZDo6LCA6OnBvc3RJZDo6KTtyZXR1cm4gZmFsc2U7Ij4KICAgICAgICDjgZ3jgYbjgafjgoLjgarjgYQKICAgICAgPC9hPgogICAgICA6OmVsc2U6OgogICAgICA8YSBocmVmPSIjIiBvbmNsaWNrPSJNeVBhZ2UuZmF2b3IoOjpyaWJib25JZDo6LCA6OnBvc3RJZDo6KTtyZXR1cm4gZmFsc2U7Ij4KICAgICAgICDjgZ3jgYbjgYvjgoIKICAgICAgPC9hPgogICAgICA6OmVuZDo6CiAgICAgIDo6ZW5kOjoKICAgICAgOjplbmQ6OgogICAgPC9zcGFuPgogIDwvZGl2PgogIDxkaXYgY2xhc3M9ImNvbnRlbnQiPgogICAgOjpjb250ZW50OjoKICA8L2Rpdj4KPC9kaXY+Cg"}];
haxe.Template.splitter = new EReg("(::[A-Za-z0-9_ ()&|!+=/><*.\"-]+::|\\$\\$([A-Za-z0-9_-]+)\\()","");
haxe.Template.expr_splitter = new EReg("(\\(|\\)|[ \r\n\t]*\"[^\"]*\"[ \r\n\t]*|[!+=/><*.&|-]+)","");
haxe.Template.expr_trim = new EReg("^[ ]*([^ ]+)[ ]*$","");
haxe.Template.expr_int = new EReg("^[0-9]+$","");
haxe.Template.expr_float = new EReg("^([+-]?)(?=\\d|,\\d)\\d*(,\\d*)?([Ee]([+-]?\\d+))?$","");
haxe.Template.globals = { };
haxe.crypto.Base64.CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
haxe.crypto.Base64.BYTES = haxe.io.Bytes.ofString(haxe.crypto.Base64.CHARS);
MyPage.main();
})(typeof window != "undefined" ? window : exports);
