(function () {
  // Build an "On this page" navigation aside on every page that has one.
  // Reads <h2> and <h3> headings from the main content area; renders a nested
  // <ul> matching the homepage's hardcoded TOC. Hides the aside when there
  // are fewer than 2 H2 headings (single-section pages don't benefit).
  var aside = document.querySelector('aside.page-toc[data-auto-toc]');
  if (!aside) return;

  var content = document.querySelector('.main-content');
  if (!content) {
    aside.style.display = 'none';
    return;
  }

  // Collect H2/H3 from content, skip anything inside the aside itself.
  var headings = [].slice.call(content.querySelectorAll('h2[id], h3[id]')).filter(function (h) {
    return !aside.contains(h);
  });
  var h2s = headings.filter(function (h) { return h.tagName === 'H2'; });
  if (h2s.length < 2) {
    aside.style.display = 'none';
    return;
  }

  var rootList = document.createElement('ul');
  var current = rootList;
  var lastH2Item = null;

  headings.forEach(function (h) {
    var li = document.createElement('li');
    var a = document.createElement('a');
    a.href = '#' + h.id;
    a.textContent = h.textContent.trim();
    li.appendChild(a);

    if (h.tagName === 'H2') {
      rootList.appendChild(li);
      lastH2Item = li;
      current = rootList;
    } else if (h.tagName === 'H3' && lastH2Item) {
      var sublist = lastH2Item.querySelector('ul');
      if (!sublist) {
        sublist = document.createElement('ul');
        lastH2Item.appendChild(sublist);
      }
      sublist.appendChild(li);
    }
  });

  var heading = document.createElement('h4');
  heading.textContent = 'On this page';
  aside.innerHTML = '';
  aside.appendChild(heading);
  aside.appendChild(rootList);
})();
