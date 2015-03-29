//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

module.exports = function(I18n) {

  var latestId = 0;

  return {
    restrict: 'A',
    scope: {
      scales: '=',
      selectedScale: '='
    },
    templateUrl: '/templates/components/zoom_slider.html',
    link: function(scope, element, attributes) {
      scope.minValue = 1;
      scope.maxValue = scope.scales.length;
      scope.sliderId = 'zoom-slider-' + latestId++;
      scope.labelText = I18n.t('js.timelines.zoom.slider');

      var slider = element.find('input');
      slider.on('change', function() {
        scope.selectedScaleIndex = slider.val() - 1;
        scope.selectedScale = scope.scales[scope.selectedScaleIndex];
        scope.$apply();
      });

      scope.$watch('selectedScale', function(newScale) {
        var newIndex = scope.scales.indexOf(newScale);

        if (scope.selectedScaleIndex !== newIndex) {
          scope.selectedScaleIndex = newIndex;
        }
      });

    }
  };
};
