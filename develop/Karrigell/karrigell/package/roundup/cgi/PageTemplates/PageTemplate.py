##############################################################################
#
# Copyright (c) 2001 Zope Corporation and Contributors. All Rights Reserved.
#
# This software is subject to the provisions of the Zope Public License,
# Version 2.0 (ZPL).  A copy of the ZPL should accompany this distribution.
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY AND ALL EXPRESS OR IMPLIED
# WARRANTIES ARE DISCLAIMED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF TITLE, MERCHANTABILITY, AGAINST INFRINGEMENT, AND FITNESS
# FOR A PARTICULAR PURPOSE
#
##############################################################################
# Modified for Roundup:
# 
# 1. changed imports to import from roundup.cgi
# 2. removed use of ExtensionClass
# 3. removed use of ComputedAttribute
"""Page Template module

HTML- and XML-based template objects using TAL, TALES, and METAL.
"""

__version__='$Revision: 1.5 $'[11:-2]

import sys

from roundup.cgi.TAL.TALParser import TALParser
from roundup.cgi.TAL.HTMLTALParser import HTMLTALParser
from roundup.cgi.TAL.TALGenerator import TALGenerator
# Do not use cStringIO here!  It's not unicode aware. :(
from roundup.cgi.TAL.TALInterpreter import TALInterpreter, FasterStringIO
from Expressions import getEngine


class PageTemplate:
    "Page Templates using TAL, TALES, and METAL"

    content_type = 'text/html'
    expand = 0
    _v_errors = ()
    _v_warnings = ()
    _v_program = None
    _v_macros = None
    _v_cooked = 0
    id = '(unknown)'
    _text = ''
    _error_start = '<!-- Page Template Diagnostics'

    def StringIO(self):
        # Third-party products wishing to provide a full Unicode-aware
        # StringIO can do so by monkey-patching this method.
        return FasterStringIO()

    def pt_edit(self, text, content_type):
        if content_type:
            self.content_type = str(content_type)
        if hasattr(text, 'read'):
            text = text.read()
        self.write(text)

    def pt_getContext(self):
        c = {'template': self,
             'options': {},
             'nothing': None,
             'request': None,
             'modules': ModuleImporter,
             }
        parent = getattr(self, 'aq_parent', None)
        if parent is not None:
            c['here'] = parent
            c['container'] = self.aq_inner.aq_parent
            while parent is not None:
                self = parent
                parent = getattr(self, 'aq_parent', None)
            c['root'] = self
        return c

    def pt_render(self, source=0, extra_context={}):
        """Render this Page Template"""
        if not self._v_cooked:
            self._cook()

        __traceback_supplement__ = (PageTemplateTracebackSupplement, self)

        if self._v_errors:
            raise PTRuntimeError, 'Page Template %s has errors.' % self.id
        output = self.StringIO()
        c = self.pt_getContext()
        c.update(extra_context)

        TALInterpreter(self._v_program, self._v_macros,
                       getEngine().getContext(c),
                       output,
                       tal=not source, strictinsert=0)()
        return output.getvalue()

    def __call__(self, *args, **kwargs):
        if not kwargs.has_key('args'):
            kwargs['args'] = args
        return self.pt_render(extra_context={'options': kwargs})

    def pt_errors(self):
        if not self._v_cooked:
            self._cook()
        err = self._v_errors
        if err:
            return err
        if not self.expand: return
        try:
            self.pt_render(source=1)
        except:
            return ('Macro expansion failed', '%s: %s' % sys.exc_info()[:2])

    def pt_warnings(self):
        if not self._v_cooked:
            self._cook()
        return self._v_warnings

    def pt_macros(self):
        if not self._v_cooked:
            self._cook()
        __traceback_supplement__ = (PageTemplateTracebackSupplement, self)
        if self._v_errors:
            raise PTRuntimeError, 'Page Template %s has errors.' % self.id
        return self._v_macros

    def __getattr__(self, name):
        if name == 'macros':
            return self.pt_macros()
        raise AttributeError, name

    def pt_source_file(self):
        return None  # Unknown.

    def write(self, text):
        assert type(text) is type('')
        if text[:len(self._error_start)] == self._error_start:
            errend = text.find('-->')
            if errend >= 0:
                text = text[errend + 4:]
        if self._text != text:
            self._text = text
        self._cook()

    def read(self):
        self._cook_check()
        if not self._v_errors:
            if not self.expand:
                return self._text
            try:
                return self.pt_render(source=1)
            except:
                return ('%s\n Macro expansion failed\n %s\n-->\n%s' %
                        (self._error_start, "%s: %s" % sys.exc_info()[:2],
                         self._text) )

        return ('%s\n %s\n-->\n%s' % (self._error_start,
                                      '\n '.join(self._v_errors),
                                      self._text))

    def _cook_check(self):
        if not self._v_cooked:
            self._cook()

    def _cook(self):
        """Compile the TAL and METAL statments.

        Cooking must not fail due to compilation errors in templates.
        """
        source_file = self.pt_source_file()
        if self.html():
            gen = TALGenerator(getEngine(), xml=0, source_file=source_file)
            parser = HTMLTALParser(gen)
        else:
            gen = TALGenerator(getEngine(), source_file=source_file)
            parser = TALParser(gen)

        self._v_errors = ()
        try:
            parser.parseString(self._text)
            self._v_program, self._v_macros = parser.getCode()
        except:
            self._v_errors = ["Compilation failed",
                              "%s: %s" % sys.exc_info()[:2]]
        self._v_warnings = parser.getWarnings()
        self._v_cooked = 1

    def html(self):
        if not hasattr(getattr(self, 'aq_base', self), 'is_html'):
            return self.content_type == 'text/html'
        return self.is_html

class _ModuleImporter:
    def __getitem__(self, module):
        mod = __import__(module)
        path = module.split('.')
        for name in path[1:]:
            mod = getattr(mod, name)
        return mod

ModuleImporter = _ModuleImporter()

class PTRuntimeError(RuntimeError):
    '''The Page Template has template errors that prevent it from rendering.'''
    pass


class PageTemplateTracebackSupplement:
    #__implements__ = ITracebackSupplement

    def __init__(self, pt):
        self.object = pt
        w = pt.pt_warnings()
        e = pt.pt_errors()
        if e:
            w = list(w) + list(e)
        self.warnings = w

