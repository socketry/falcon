// This file is part of the "jQuery.Syntax" project, and is distributed under the MIT License.
Syntax.brushes.dependency("php","php-script");Syntax.register("php",function(a){a.push({pattern:/(<\?(php)?)((.|\n)*?)(\?>)/gm,matches:Syntax.extractMatches({klass:"keyword"},null,{brush:"php-script"},null,{klass:"keyword"})})});
