---
title: SASS - Convert px to rem
tags: [blog, snippet]
date: 2020-12-29
---

When we speak about significant CSS codebase, we automatically think of SASS or any other CSS pre-processor like stylus or LESS, to name a few. Using this type of tool is useful not only to share styles across multiple components, nesting, variables but also to allow [functions](https://sass-lang.com/documentation/at-rules/function) and [mixins](https://sass-lang.com/documentation/at-rules/mixin) for more complex logic.

<!-- more -->

## Pixels

Pixels are the most well-known unit in the world of web development. Everyone knows what a pixel is, but it is necessary to keep in mind that it doesn't always have the same size - for example, screens have different pixel densities. Since the designer work with pixels, it can be tempting to use pixels everywhere. So what is the problem of using pixels in every situation?

### Accessibility

Personally, I chose a well developed/planned feature and accessibility over the "prettiness" of a design. However, I love simples, clean and modern design, so bringing the two things together is the best-case scenario. Accessibility should be a default instead of a feature.

The ability to change the default font-size is a feature that most of the browser users don't know about, but there is a small percentage of users who use it, mainly due to visual disabilities. Traditionally, browsers set the default font-size to 16 pixels, but it can be changed, and when using pixels, bad things can happen. Defining a font, for example, with a size of 25px even when the user changes the default size that 25px will forever have that value - this completely destroys accessibility.

Fortunately, browsers have a zoom feature that can be used to "scale" the whole website evenly, but this isn't great in some situations; rightly scaling the website elements would be a better approach.

## REMs

REM units arrived alongside with CSS3 specification and came to solve some specific scenarios. Of course that if you are a web developer, you probably already know what is a REM. If you're not, REMs are a way of setting font-sizes and any other element dimension based on the font-size of the HTML root element. They also allow you to scale the entire website by just changing the root font-size with no additional changes or JavaScript.

### How can I convert Pixels to REMs?

To do the calculations, you just need to have in mind that you need to know the root font-size since we will use it as our base on our math.

For example, take into account the base size is 16px, which always corresponds to a 1rem. You just need to make a simple rule of three to find the value. So the math function to it is described as:

```text
f(x) = x / root_font_size
```

## SASS to the rescue

To make the process easier and since the design specifications usually come in pixels, the easier way is to continue using pixels on the code but convert it to REMs using SASS.

To achieve that, the better way to take advantage of SASS functions and create one that computes the REM value values considering the base size of the fount. Something like this:

```scss
// define base font size of the HTML root
$base-size: 16px;

// function to convert px to rem
//
// the second argument allows to specify the base for special cases, but is totally optional
@function rem($size, $context: $base-size) {
  @return $size / $context * 1rem;
}
```

To use the implementation above, call it on the property that you want to convert:

```scss
body {
  margin: rem(20);
}
```

This way, you can quickly implement the design specification without the need to do manual calculations and keep up with speed.
