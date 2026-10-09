using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Options;

namespace CareApp.Api.ErrorHandling;

/// <summary>
/// Runs the FluentValidation validator registered for each action argument, if any, and short-circuits
/// with the same 400 ValidationProblemDetails response used for model binding errors.
/// </summary>
internal sealed class ValidationFilter : IAsyncActionFilter
{
    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        var services = context.HttpContext.RequestServices;

        foreach (var argument in context.ActionArguments.Values)
        {
            if (argument is null
                || services.GetService(typeof(IValidator<>).MakeGenericType(argument.GetType())) is not IValidator validator)
            {
                continue;
            }

            var result = await validator.ValidateAsync(
                new ValidationContext<object>(argument), context.HttpContext.RequestAborted);

            foreach (var error in result.Errors)
            {
                context.ModelState.AddModelError(error.PropertyName, error.ErrorMessage);
            }
        }

        if (!context.ModelState.IsValid)
        {
            var apiBehavior = services.GetRequiredService<IOptions<ApiBehaviorOptions>>().Value;
            context.Result = apiBehavior.InvalidModelStateResponseFactory(context);
            return;
        }

        await next();
    }
}
