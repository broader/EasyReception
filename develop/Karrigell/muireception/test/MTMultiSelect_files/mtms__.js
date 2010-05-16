window.addEvent('domready', function (){    
     $$('.multiselect').each(function(multiselect){
        new MTMultiWidget({'datasrc': multiselect});
    });
});